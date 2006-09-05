function this = testProperties

this = inherit(...
    TestCase()...
    ,public(...
    @testPropertyGetting...
    ,@testPropertySetting...
    ,@testPropertyInheritance...
    ,@testPropertyOverride...
    ,@testReferenceBehavior...
    ,@testPropertyOverrideInChild...
    ,@testMethodMethod...
    ,@testPropertyMethod...
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

    function testPropertyOverrideInChild
        function this = Parent
            %inherit is not getting the method__ right...
            this = inherit(properties('a', 1), public(@doubleA));
            
            function aa = doubleA
                aa = 2 * this.getA();
            end
        end
        
        function this = Child
            [this, parent_] = inherit(Parent(), public(@getA));
            
            function a = getA
                a = parent_.getA() + 1;
            end
        end
        
        c = Child();
        c.setA(4);
        assertEquals(10, c.doubleA());
        
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

    function increment_b(props)
        props.setB(props.getB() + 1);
    end

    function testMethodMethod
        p = properties('a', 1, 'b', 2);
        assertEquals({'getA', 'getB', 'setA', 'setB'}', sort(p.method__()));
        getter = functions(p.method__('getA'));
        assertEquals('accessor/getter', getter.function);
        
        %this should not error (but doesn't do anything really)
        p.method__('getA', @()1);
            
    end

    function testPropertyMethod
        p = properties('a', 1, 'b', 2);
        assertEquals({'a', 'b'}', sort(p.property__()));
        assertEquals(1, p.property__('a'));
        p.property__('a', 3);
        assertEquals(3, p.property__('a'));
    end

end
