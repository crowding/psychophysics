function this = testFinalize
    %finalize strips from an object all metadata and the ability to be
    %inherited from. Because it removes a layer of nested function
    %indirection, invoking methods on finalized objects is faster.
    
    this = inherit(TestCase()...
        ,public(...
        @testFinalize...
        ,@testFinalizeInherited...
        ,@testMethodMethod...
        ));

    function testFinalize()
        r = TestObj();
        function this = TestObj
            this = public(@foo);
            function foo
            end
        end
        
        assertEquals('publicize/reassignableFunction/invoke', func2str(r.foo));
        
        r = finalize(r);
        assertEquals('testFinalize/testFinalize/TestObj/foo', func2str(r.foo));
        
    end

    function testFinalizeInherited()
        r = TestObj();
        function this = TestObj
            this = inherit(TestParent, public(@bar, @baz));
            function bar
            end
            
            function baz
            end
        end
        function this = TestParent
            this = public(@foo, @bar);
            function foo
            end
            
            function bar
            end
        end
        
        assertEquals('publicize/reassignableFunction/invoke', func2str(r.foo));
        assertEquals('publicize/reassignableFunction/invoke', func2str(r.bar));
        assertEquals('publicize/reassignableFunction/invoke', func2str(r.baz));
        
        r = finalize(r);
        
        assertEquals('testFinalize/testFinalizeInherited/TestParent/foo', func2str(r.foo));
        assertEquals('testFinalize/testFinalizeInherited/TestObj/bar', func2str(r.bar));
        assertEquals('testFinalize/testFinalizeInherited/TestObj/baz', func2str(r.baz));

    end

    function testMethodMethod()
        r = finalize(TestObj());
        function this = TestObj
            this = public(@foo);
            function f = foo
                f = 1;
            end
        end

        assertEquals({'foo'}, r.method__());
        fn = r.method__('foo');
        assertEquals(1, fn());
        try
            r.method('foo', 'bar')
            fail('should have error');
        catch
        end
    end
end