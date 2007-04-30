function this = testRequire
%A test suite exercising the 'require' resource acquisition functions. 

%public methods and properties
%note: this is well and good for objects, where you want to keep track of
%your interfaces, but for unit tests where you want to throw in a bunch of
%test functions and make everything work, I can see the virtues of a
%scanning technique.
this = inherit(...
    TestCase()...
    ,public(...
        @testRequiresTwoArguments,...
        @testCanTakeVarargout,...
        @testNeedsInitFunctionHandle,...
        @testNeedsReleaseFunctionHandle,...
        ...%@testRobustToTypos,... %these are not specified behavior right now
        ...%@testRobustToMultipleTypos,...
        @testNeedsOutputArg,...
        @testFailedInit,...
        @testFailedBody,...
        @testFailedRelease,...
        @testFailedReleaseAfterFailedBody,...
        @testFailedReleaseLogsAdditionalError,...
        @testOutputCollection,...
        @testBodyOutput,...
        ...
        @testSuccessfulChain,...
        @testFailedChainInit,...
        @testFailedChainRelease,...
        @testFailedChainBody,...
        @testFailedChainBodyRelease,...
        @testChainOutputCollection,...
        ...
        @testSuccessfulJoin,...
        @testFailedJoinInit,...
        @testFailedJoinRelease,...
        @testFailedJoinBody,...
        @testFailedJoinBodyRelease,...
        @testJoinOutputCollection));

%method definitions
%---input constraint tests---
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
        
        function [r, o] = init(o)
            r = 5678;
        end
    end

    function testRobustToTypos
        %if you miss an @sign, you might call initialization before getting
        %into require, but require will then call the release function
        %handle that it gets instead. This won't work so well for
        %multiple-argument invocations, however. Maybe it should?
        %
        %this behavior is intended as a development convenience.
        rflag = 0;
        try
            require(init, @noop)
            fail('expected error');
        catch
            assertLastError('testrequire:');
        end
        assert(rflag);
        
        function r = init
            r = @release;
            
            function release
                rflag = 1;
            end
        end
    end

    function testRobustToMultipleTypos
        %not sur whether I should make it pass this test, since it's a
        %modification of otherwise reasonable behavior. If not havign
        %it is a problem, we'll see.
        fail('test not written')
    end

    function testNeedsOutputArg
        %require expects a function handle from executing the initializer
        try
            require(@init, @noop);
            fail('expected error');
        catch
            assertLastError('MATLAB:');
        end
        
        function init(o)
        end
    end

    function testNeedsTwoOutputs
        %all initializers need to produce two outputs.
        try
            require(@init, @noop);
            fail('expected error');
        catch
            assertLastError('require:');
        end
        
        function r = init(o)
            r = @noop;
        end
    end

    function testCanTakeVarargout
        %initializers can be functions declaring variable numbers of
        %outputs (nice for currying...)
        
        assertEquals(-1, nargout(@init));
        require(@init, @noop);
        
        function varargout = init(in)
            varargout = {@noop, in};
        end
    end
        
%---single initializer tests
    function testFailedInit
        %when init fails, the main body is not executed, and
        %the exception is propagated
        
        try
            require(@init, @body)
            fail('expected error');
        catch
            assertLastError('testRequire:');
        end
        
        function [r, o] = init(o)
            error('testRequire:test', 'test');
            r = @noop;
        end
        
        function body
            fail('body should not be run')
        end 
    end            
            
    function testFailedBody        
        %when the body fails, cleanup should be executed and
        %the exception propagated.
        
        releaseflag = 0;
        try
            require(@init, @body)
            fail('expected error');
        catch
            assertLastError('testRequire:');
            assert(releaseflag);
        end
        
        function [r, o] = init(o)
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

        function [r, o] = init(o)
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
            assert(bflag);
        end
        
        function [r, o] = init(o)
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

    function testFailedReleaseLogsAdditionalError
        %when the release fails after the body fails, the ORIGINAL
        %exception is rethrown.
        
        try
            require(@init, @body)
            fail('expected an error');
        catch
            assertLastError('testRequire:expectedError');
            %at the appropriate stack frame, the additional error should be
            %logged (since in MATALB's errors we can apparently plug in
            %fields to the stack trace but not to the error structure)
            e = lasterror();
            found = 0;
            for i = e.stack(:)'
                if ~isempty(i.additional) 
                    if strcmp(i.additional.identifier, 'testRequire:additionalError');
                        found = 1;
                    end
                end
            end
            assert(found, 'didn''t find attached exception');
        end
        
        function [r, o] = init(o)
            r = @release;
            
            function release
                error('testRequire:expectedError', 'test');
            end
        end

        function body
            error('testRequire:additionalError', 'test');
        end
    end

    function testOutputCollection
        %An initializer function has two outputs, and the second otuput
        %can be passed to the main body.
        bflag = 0;
        require(@init, @body);
        assert(bflag);
        
        function [r, o] = init(o)
            assertEquals(struct(), o);
            o = struct('foo', 1);
            r = @noop;
        end
        
        function body(o)
            assertEquals(struct('foo', 1), o);
            bflag = 1;
        end
    end

    function testBodyOutput
        %output from the body is captured and returned.
        [a, b] = require(@init, @body);
        assertEquals([1 2], [a b]);
        
        function [r, o] = init(o)
            r = @noop;
        end
        
        function [a, b] = body(o)
            a = 1;
            b = 2;
        end 
    end
        
%---multiple initializer tests

    function testSuccessfulChain
        %Multiple (i.e. 2) cleanups and releases will do cleaning-up and
        %releasing in first-in, first-out order.
        [iflag1, iflag2, rflag1, rflag2] = deal(0);
        
        require(@init1, @init2, @noop)
        assertEquals([1 1 1 1],[iflag1 iflag2 rflag1 rflag2]);
        
        function [r, o] = init1(o)
            assertEquals([0 0 0 0],[iflag1 iflag2 rflag1 rflag2]);
            iflag1 = 1;
            r = @release1;

            function release1
                assertEquals([1 1 0 1],[iflag1 iflag2 rflag1 rflag2]);
                rflag1 = 1;
            end
        end

        function [r, o] = init2(o)
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
        
        function [r, o] = init1(o)
            r = @release1;
            
            function release1
                rflag = 1; 
            end
        end
        
        function [r, o] = init2(o)
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
        
        function [r, o] = init1(o)
            r = @release1;
            
            function release1
                rflag = 1; 
            end
        end
        
        function [r, o] = init2(o)
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
        
        function [r, o] = init1(o)
            r = @release;
            
            function release
            end
        end
        
        function [r, o] = init2(o)
            r = @release;
            
            function release
            end
        end
        
        function body
            error('testRequire:expected', 'test');
        end
    end

    function testFailedChainBodyRelease
        %when a body fails, AND THEN a release fails, preceding resources
        %are released, and the releaser's exception is propagated.
        rflag1 = 0;
        rflag2 = 0;
        
        try
            require(@init1, @init2, @body);
            fail('expected an error');
        catch
            assertLastError('testRequire:releaser');
            assert(rflag1);
            assert(rflag2);
        end
        
        function [r,o] = init1(o)
            r = @release;
            
            function release
                rflag1 = 1; 
            end
        end
        
        function [r,o] = init2(o)
            r = @release;
            
            function release
                rflag2 = 1;
                error('testRequire:releaser', 'test');
            end
        end
        
        function body
            error('testRequire:body', 'test');
        end
    end

    function testChainOutputCollection
        %The initialization struct os passed through each initializer and
        %into the body. A empty struct is given as first argument.

        bflag = 0;
        require(@init1, @init2, @body);
        assert(bflag);
        
        function body(o)
            assertEquals(1, nargin); 
            assertEquals(struct('i', 1, 'j', 2), o);
            bflag = 1;
        end
        
        function [r, o] = init1(o)
            r = @noop;
            o.i = 1;
        end
            
        function [r, o] = init2(o)
            r = @noop;
            o.j = 2;
        end
    end
    
%---joined initializer test

    function testSuccessfulJoin
        %Multiple (i.e. 2) cleanups and releases will do cleaning-up and
        %releasing in first-in, first-out order.
        [iflag1, iflag2, rflag1, rflag2] = deal(0);
        r = joinResource(@init1, @init2);
        require(r, @body)
        assertEquals([1 1 1 1],[iflag1 iflag2 rflag1 rflag2]);
        
        function [r,o] = init1(o)
            assertEquals([0 0 0 0],[iflag1 iflag2 rflag1 rflag2]);
            iflag1 = 1;
            r = @release1;

            function release1
                assertEquals([1 1 0 1],[iflag1 iflag2 rflag1 rflag2]);
                rflag1 = 1;
            end
        end

        function [r,o] = init2(o)
            assertEquals([1 0 0 0],[iflag1 iflag2 rflag1 rflag2]);
            iflag2 = 1;
            r = @release2;
            
            function release2
                assertEquals([1 1 0 0],[iflag1 iflag2 rflag1 rflag2]);
                rflag2 = 1;
            end
        end
        
        function body
            assertEquals([1 1 0 0],[iflag1 iflag2 rflag1 rflag2]);
        end
    end

    function testFailedJoinInit
        %when a chained initialization fails, preceding initilizations are
        %released.
        rflag = 0;
        r = joinResource(@init1, @init2);
        try
            require(r, @noop)
            fail('expected error');
        catch
            assertLastError('testRequire:');
            assert(rflag);
        end
        
        function [r, o] = init1(o)
            r = @release1;
            
            function release1
                rflag = 1; 
            end
        end
        
        function [r, o] = init2(o)
            r = @()error('testRequire:test', 'test');
        end
    end

    function testFailedJoinRelease
        %when a chained release fails, subsequent releases are still
        %executed, before the exception is propagated.
        rflag = 0;
        r = joinResource(@init1, @init2);
        try
            require(r, @noop)
            fail('expected error');
        catch
            assertLastError('testRequire:');
            assert(rflag); %the flag was released
        end
        
        function [r, o] = init1(o)
            r = @release1;
            
            function release1
                rflag = 1; 
            end
        end
        
        function [r, o] = init2(o)
            r = @()error('testRequire:test', 'test');
        end
    end

    function testFailedJoinBody
        %when a body fails with chained resources, all the resources are
        %released and the exception is propagated.
        try
            r = joinResource(@init1, @init2);
            require(r, @body);
            fail('expected an error');
        catch
            assertLastError('testRequire:expected');
        end
        
        function [r, o] = init1(o)
            r = @release;
            
            function release
            end
        end
        
        function [r, o] = init2(o)
            r = @release;
            
            function release
            end
        end
        
        function body
            error('testRequire:expected', 'test');
        end
    end

    function testFailedJoinBodyRelease
        %when a body fails, AND THEN a release fails, preceding resources
        %are released, and the releaser's exception is propagated.
        %unfortunately, I don't have a way to chain exceptions with their
        %antecedent causes. 
        rflag1 = 0;
        rflag2 = 0;
        
        try
            r = joinResource(@init1, @init2);
            require(r, @body);
            fail('expected an error');
        catch
            assertLastError('testRequire:releaser');
            assert(rflag1);
            assert(rflag2);
        end
        
        function [r, o] = init1(o)
            r = @release;
            
            function release
                rflag1 = 1; 
            end
        end
        
        function [r, o] = init2(o)
            r = @release;
            
            function release
                rflag2 = 1;
                error('testRequire:releaser', 'test');
            end
        end
        
        function body
            error('testRequire:body', 'test');
        end
    end

    function testJoinOutputCollection
        %the initialization struct is passed down through each initializer
        %and then into the body.

        bflag = 0;
        r = joinResource(@init1, @init2);
        require(r, @body);
        assert(bflag);
        
        function body(in)
            assertEquals(1, nargin); 
            assertEquals(struct('a', 1, 'b', 2, 'c', 2), in);
            bflag = 1;
        end
        
        function [r, o] = init1(o)
            r = @noop;
            o = struct('a', 1, 'b', 1);
        end
            
        function [r, o] = init2(o)
            %note passing through of outputs
            r = @noop;
            assertEquals(struct('a', 1, 'b', 1), o);
            o.b = 2;
            o.c = 2;
        end
    end

    function noop
    end

end