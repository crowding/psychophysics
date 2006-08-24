function this = testHandlers
this = inherit(TestCase,...
    public(...
     @testIdentifier...
    ,@testIdentifierInitialFragment...
    ,@testRethrow...
    ,@testArgument...
    ,@testBadIdentifier...
    ,@testBadHandler...
    ,@testOutput...
    ));


    function testIdentifier
        flag = 0;
        try
            error('complete:identifier', 'mesage')
        catch
            handlers(...
                'complete:identifier', @handler);
        end
        function handler(err)
            assertEquals(err.identifier, 'complete:identifier');
            flag = 1;
        end

        assert(flag);
    end


    function testIdentifierInitialFragment
        flag = 0;
        try
            error('simpleIdentifier:thing', 'message')
        catch
            handlers(...
                'simpleIdentifier:', @handler);
        end
        function handler(err)
            assertEquals(err.identifier, 'simpleIdentifier:thing');
            flag = 1;
        end

        assert(flag);
    end


    function testRethrow
        try
            try
                error('uncaught:identifier', 'message')
            catch
                handlers(...
                    'simpleIdentifier:', @handler);
                fail('expected an error');
            end
        catch
            assertLastError('uncaught:identifier');
        end
        function handler(err)
            fail('should not handle')
        end
    end


    function testArgument
        flag = 0;
        handlers(...
            struct('identifier', 'complete:identifier', 'message', 'message'),...
            'complete:identifier', @handler);
        
        assert(flag);
        
        function handler(err)
            assertEquals(err.identifier, 'complete:identifier');
            flag = 1;
        end
    end
    
    function testBadIdentifier
        try
            handlers('foo:bar', @handler, 1234, @handler);
            fail('expected error');
        catch
            assertLastError('handlers');
        end
    end

    function testBadHandler
        try
            handlers('foo:bar', @handler, 'baz:', 1234);
            fail('expected error');
        catch
            assertLastError('handlers');
        end
    end
        
    function testOutput
        out = handlers(...
            struct('identifier', 'complete:identifier', 'message', 'message'),...
            'complete:identifier', @handler);
        
        assertEquals('foo', out);
        
        function r = handler(err)
            r = 'foo';
        end
    end
end