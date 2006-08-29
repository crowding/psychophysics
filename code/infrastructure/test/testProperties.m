function this = testProperties

this = inherit(...
    TestCase()...
    ,public(...
    @testPropertyGetting...
    ,@testPropertySetting...
    ,@testPropertyInheritance...
    ,@testPropertyOverride...
    ,@testReferenceBehavior...
    ,@testPropertiesField...
    ));

    function testPropertyGetting
        p = properties('a', 1, 'b', 'foo', 'c', {3});
        
        assertEquals(1,     p.getA());
        assertEquals('foo', p.getB());
        assertEquals({3},   p.getC());
    end


    function testPropertySetting
        p = properties('a', 1, 'b', 'foo', 'c', {3});
        p.setA('bar');
        p.setB({'baz' 'qux'});
        p.setC([12 32]);
        
        assertEquals('bar',         p.getA());
        assertEquals({'baz' 'qux'}, p.getB());
        assertEquals([12 32],       p.getC());
    end

    function testPropertyInheritance
        function this = TestObject
            this = inherit(properties('value', 1), public(@increment));
            
            function increment
                this.setValue(this.getValue() + 1);
            end
        end
        
        a = TestObject();
        
        assertEquals(a.getValue(), 1);
        a.increment();
        assertEquals(a.getValue(), 2);
        a.increment();
        assertEquals(a.getValue(), 3);
    end


    function testPropertyOverride
        %Shows how to override the property accessors made by
        %properties().
        function this = TestObject
            %p_ will contain a reference to the properties methods before 
            %overriding
            [this, p_] = inherit(...
                properties('a', 1, 'b', 2),...
                public(@getB, @setB, @sum)...
            );
        
            function val = setB(val)
                %override the property accessor so that
                %b gets rounded to integers
                p_.setB(round(val));
            end

            function val = getB()
                val = p_.getB();
            end

            function s = sum()
                s = this.getA() + this.getB();
            end
        end
        
        o = TestObject();
        assertEquals(o.getA(), 1);
        assertEquals(o.getB(), 2);
        assertEquals(o.sum(), 3);
        
        %set a and b, but b gets rounded
        o.setA(2.25);
        o.setB(3.75);
        
        assertEquals(2.25, o.getA());
        assertEquals(4, o.getB());
        assertEquals(o.sum(), 6.25);
    end


    function testReferenceBehavior
        p = properties('a', 1, 'b', 2);
        
        assertEquals(1, p.getA());
        assertEquals(2, p.getB());
        increment_b(p);
        assertEquals(3, p.getB());
    end

    function testPropertiesField
        p = properties('a', 1, 'c', 2, 'b', 3);
        assert(strmatch('a', p.properties__));
        assert(strmatch('b', p.properties__));
        assert(strmatch('c', p.properties__));
    end

    function increment_b(props)
        props.setB(props.getB() + 1);
    end

end
