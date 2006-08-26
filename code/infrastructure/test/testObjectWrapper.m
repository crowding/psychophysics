function this = testObjectWrapper()

    this = inherit(TestCase(), public(...
        @testInvoke...
        ,@testInvokeMultipleOutputs...
        ,@testInvokeNoOutputs...
        ));
    
    function testInvoke()
        %should be able to invoke just like a struct-object

        testobj = ObjectWrapper(public(@helloworld));
        function r = helloworld
            r = 'Hello, world!';
        end
        
        assertEquals(testobj.helloworld(), 'Hello, world!');
    end

    function testInvokeMultipleOutputs()
        %invoke should work with multiple outputs
        testobj = ObjectWrapper(public(@helloworld));
        function [r, j] = helloworld
            r = 'hello';
            j = 'world';
        end
        
        [a, b] = testobj.helloworld();
        assertEquals(a, 'hello');
        assertEquals(b, 'world');
    end

    function testInvokeNoOutputs()
        %and multiple inputs
        flag = 0;
        
        testobj = ObjectWrapper(public(@helloworld));
        function helloworld
            flag = 1;
        end
        
        testobj.helloworld();
        assert(flag);
    end
end