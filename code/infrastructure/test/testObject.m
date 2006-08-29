function this = testObject()

    this = inherit(TestCase(), public(...
        @testInvoke...
        ,@testInvokeMultipleOutputs...
        ,@testInvokeNoOutputs...
        ,@testPropertyGetting...
        ,@testPropertySetting...
        ,@testPropertyChainGetting...
        ,@testPropertyChainSetting...
        ,@testPropertyOverride...
        ,@testLoadSaveFilter...
        ,@testConstructorReference...
        ,@testPropertyMethods...
        ));
    
    function testInvoke
        %should be able to invoke just like a struct-object

        testobj = Object(public(@helloworld));
        function r = helloworld
            r = 'Hello, world!';
        end
        
        assertEquals(testobj.helloworld(), 'Hello, world!');
    end

    function testInvokeMultipleOutputs
        %invoke should work with multiple outputs
        testobj = Object(public(@helloworld));
        function [r, j] = helloworld
            r = 'hello';
            j = 'world';
        end
        
        [a, b] = testobj.helloworld();
        assertEquals(a, 'hello');
        assertEquals(b, 'world');
    end

    function testInvokeNoOutputs
        %and multiple inputs
        flag = 0;
        
        testobj = Object(public(@helloworld));
        function helloworld
            flag = 1;
        end
        
        testobj.helloworld();
        assert(flag);
    end

    function testPropertyGetting
        %you should be able to get the value of a property as though it
        %were a field.
        testobj = Object(properties('test', 1));
        
        assertEquals(1, testobj.test);
    end

    function testPropertySetting
        %you should be able to assign properties, while maintaining
        %reference semantics.
        testobj = Object(properties('test', 1));
        testobk = testobj;
        
        testobj.test = 2;
        
        assertEquals(2, testobj.test);       
        assertEquals(2, testobk.test);
    end

    function testPropertyOverride
        %you should be able to override your accessors that are
        %invoked using reference semantics.
        [testobj, props, methods] = ...
            Object(properties('test', 1), public(@getTest, @setTest));
        function t = getTest
            t = props.getTest() + 1;
        end
        function setTest(value)
            props.setTest(value*2);
        end
        
        testobj.test = 10;
        assertEquals(21, testobj.test);
    end

    function testPropertyChainGetting
        testobj = Object(...
            properties(...
                'foo', Object(properties(...
                    'bar', 2))));
        
        assertEquals(2, testobj.foo.bar);
    end

    function testPropertyChainSetting
        testobj = Object(properties( ...
            'foo', Object(properties('bar', 2))));
        
        prop = testobj.foo;
        
        testobj.foo.bar = 3;
        
        assertEquals(3, prop.bar);
    end

    function testLoadSaveFilter
        %the real reason to use object wrappers is that you can invoke save
        %and load filters, which is necessary for maintaining your data
        %under changes in code.
        testobj = Object(properties('foo', 2), public(@loadobj, @saveobj));
        function this = saveobj(this)
            this.foo = this.foo + 1;
        end

        function this = loadobj(this)
            this.foo = this.foo * 2;
        end

        file = [tempname '.mat'];
        save(file, 'testobj');
        
        loaded = load(file, 'testobj');
        assertEquals(6, loaded.testobj.foo);
    end

    function testConstructorReference
        %for future help with load filters, capture and keep around a
        %handle to the constructor.
        
        testobj = Object(properties('foo', 2));
        
        c = functions(constructor__(testobj));
        
        comp = functions(@testConstructorReference);
        
        %we can't compareEquals on function handles or workspaces that
        %contain function handles directly...
        assertEquals(c.function, comp.function);
        assertEquals(c.type, comp.type);
        assertEquals(c.file, comp.file);
    end

    function testPropertyMethods
        %you can always use method__ to get at the underlying method for an
        %object's properties -- even an inherited Object
        testobj = Object(properties('bar', 3));
        
        b = testobj.method__('getBar');
        testobj.bar = 1;
        assertEquals(1, b());
        
        sb = testobj.method__('setBar');
        sb(4);
        assertEquals(4, testobj.bar); 
    end
end
