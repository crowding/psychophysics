function this = testRequire
%A test suite exercising the 'init' functions. 

%persistent and local instance variables

%public methods and properties
%note: this is well and good for objects, where you want to keep track of
%your interfaces, but for unit tests where you want to throw in a bunch of
%test functions, I can see the virtues of a scanning technique.
this = public(...
    @testRequiresTwoArguments,...
    @testNeedsInitFunctionHandle,...
    @testNeedsReleaseFunctionHandle,...
    @testFailedInit,...
    @testFailedBody,...
    @testFailedRelease,...
    @testFailedReleaseAfterFailedBody,...
    @testSuccessfulChain,...
    @testFailedChainInit,...
    @testFailedChainRelease,...
    @testFailedChainBody,...
    @testFailedChainBodyRelease,...
    @testOutputCollection,...
    @testMultipleOutputCollection,...
    @testVarargoutNotSupported);

%private instance variables

return

%method definitions
    function testRequiresTwoArguments
        %require takes at least two arguments
        try
            require(@noop);
            fail('should have error')
        catch
            assertLastError('require:');
        end
    end

    function testNeedsInitFunctionHandle
        %require takes a function handle as first argument
        try
            require(1234, @noop); %something not a function handle for init
            fail('expected error');
        catch
            assertLastError('require:');
        end

        function r = init
            r = @noop;
        end
    end

    function testNeedsReleaseFunctionHandle
        %require expects a function handle from executing the initializer
        try
            require(@init, @noop);
            fail('expected error');
        catch
            assertLastError('require:');
        end
        
        function release = init
            release = 5678;
        end
    end

    function testNeedsOutputArg
        %require expects a function handle from executing the initializer
        try
            require(@init, @noop);
            fail('expected error');
        catch
            assertLastError('require:');
        end
        
        function init
        end
    end

    function testFailedInit
        %when init fails, the main body is not executed, and
        %the exception is propagated
        
        runflag = 0;
        try
            require(@init, @body)
            fail('expected error');
        catch
            assertLastError('testRequire:');
        end
        
        function r = init
            error('testRequire:test', 'test');
        end
        
        function body
            fail('body should not be run')
        end 
    end            
            
    function testFailedBody        
        %when the body fails, cleanup should be executed and
        %the exception propagated.
        
        releaseflag = 0;
        runflag = 0;
        try
            require(@init, @body)
            fail('expected error');
        catch
            assertLastError('testRequire:');
            assert(releaseflag);
        end
        
        function r = init
            r = @release;
            function release
                releaseflag = 1;
            end
        end
        
        function body
            error('testRequire:test', 'test');
        end
    end

    function testFailedRelease
        %when the release fails, its error should be propagated.
        try
            require(@init, @noop)
            fail('expected error');
        catch
            assertLastError('testRequire:');
        end

        function r = init
            r = @()error('testRequire:test', 'test');
        end
    end

    function testFailedReleaseAfterFailedBody
        %when the release fails after the body fails, the ORIGINAL
        %exception is rethrown.
        bflag = 0;
        
        try
            require(@init, @body)
            fail('expected an error');
        catch
            assertLastError('testRequire:expectedError');
            assert(bflag)
        end
        
        function r = init
            r = @release;
            
            function release
                error('testRequire:expectedError', 'test');
            end
        end

        function body
            bflag = 1;
            error('testRequire:unexpectedError', 'test');
        end
    end

    function testSuccessfulChain
        %Multiple (i.e. 2) cleanups and releases will do cleaning-up and
        %releasing in first-in, first-out order.
        [iflag1, iflag2, rflag1, rflag2] = deal(0);
        
        require(@init1, @init2, @noop)
        assertEquals([1 1 1 1],[iflag1 iflag2 rflag1 rflag2]);
        
        function r = init1
            assertEquals([0 0 0 0],[iflag1 iflag2 rflag1 rflag2]);
            iflag1 = 1;
            r = @release1;

            function release1
                assertEquals([1 1 0 1],[iflag1 iflag2 rflag1 rflag2]);
                rflag1 = 1;
            end
        end

        function r = init2
            assertEquals([1 0 0 0],[iflag1 iflag2 rflag1 rflag2]);
            iflag2 = 1;
            r = @release2;
            
            function release2
                assertEquals([1 1 0 0],[iflag1 iflag2 rflag1 rflag2]);
                rflag2 = 1;
            end
        end
    end

    function testFailedChainInit
        %when a chained initialization fails, preceding initilizations are
        %released.
        rflag = 0;
        try
            require(@init1, @init2, @noop)
            fail('expected error');
        catch
            assertLastError('testRequire:');
            assert(rflag);
        end
        
        function r = init1
            r = @release1;
            
            function release1
                rflag = 1; 
            end
        end
        
        function r = init2
            r = @()error('testRequire:test', 'test');
        end
    end

    function testFailedChainRelease
        %when a chained release fails, subsequent releases are still
        %executed, before the exception is propagated.
        rflag = 0;
        
        try
            require(@init1, @init2, @noop)
            fail('expected error');
        catch
            assertLastError('testRequire:');
            assert(rflag); %the flag was released
        end
        
        function r = init1
            r = @release1;
            
            function release1
                rflag = 1; 
            end
        end
        
        function r = init2
            r = @()error('testRequire:test', 'test');
        end
    end

    function testFailedChainBody
        %when a body fails with chained resources, all the resources are
        %released and the exception is propagated.
        try
            require(@init1, @init2, @body);
            fail('expected an error');
        catch
            assertLastError('testRequire:expected');
        end
        
        function r = init1
            r = @release;
            
            function release
                rflag1 = 1; 
            end
        end
        
        function r = init2
            r = @release;
            
            function release
                rflag2 = 1; 
            end
        end
        
        function body
            error('testRequire:expected', 'test');
        end
    end

    function testFailedChainBodyRelease
        %when a body fails, AND THEN a release fails, preceding resources
        %are released, and the releaser's exception is propagated.
        %unfortunately, I don't have a way to chain exceptions with their
        %antecedent causes. 
        rflag1 = 0;
        rflag2 = 0;
        
        try
            require(@init1, @init2, @body);
            fail('expected an error');
        catch
            assertLastError('testRequire:expected');
            assert(rflag1);
            assert(rflag2);
        end
        
        function r = init1
            r = @release;
            
            function release
                rflag1 = 1; 
            end
        end
        
        function r = init2
            r = @release;
            
            function release
                rflag2 = 1;
                error('testRequire:expected', 'test');
            end
        end
        
        function body
            error('testRequire:unexpected', 'test');
        end
    end

    function testOutputCollection
        %An initializer function can have two outputs, in which
        %case the second output is collected and passed to the body.
        bflag = 0;
        require(@init, @body);
        assert(bflag);
        
        function [r, o] = init
            o = 4;
            r = @noop;
        end
        
        function body(o)
            assertEquals(o, 4);
            bflag = 1;
        end
    end

    function testMultipleOutputCollection
        %multiple initializer's return values and outputs are collected,
        %and passed to the body. Multiple outputs of an initiaizer are
        %collected.

        bflag = 0;
        require(@init1, @init2, @body);
        assert(bflag);
        
        function body(i, j, k)
            assertEquals(3, nargin); 
            assertEquals([i j k], [1 2 3]);
            bflag = 1;
        end
        
        function [r, ii] = init1
            r = @noop;
            ii = 1;
        end
            
        function [r, jj, kk] = init2
            %has 3 outputs, only 2 will be used
            r = @noop;
            jj = 2;
            kk = 3;
        end
    end

    function testVarargoutNotSupported
        %initializers declaring varargout are not supported. The
        %initializer is not called.
        %
        %This behavior is a lesser of several evils around matlab's
        %varargout handling - I simply can't capture all the outputs of a
        %varargout function, so I choose to outlaw varargout here entirely.
        try
            require(@init, @noop);
            fail('expected an error');
        catch
            assertLastError('require:')
        end
        
        function [r, varargout] = init
            r = @noop
            varargout = {1};
        end
    end
    
    function noop
    end

end