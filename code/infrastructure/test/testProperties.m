function this = testProperties

this = public(...
    @testPropertyGetting...
    ,@testPropertySetting...
    ,@testPropertyInheritance...
    ,@testPropertyOverride...
    ,@testReferenceBehavior...
);


    function testPropertyGetting
        p = properties('a', 1, 'b', 'foo', 'c', {3});
        
        assertEquals(1,     p.a());
        assertEquals('foo', p.b());
        assertEquals({3},   p.c());
    end


    function testPropertySetting
        p = properties('a', 1, 'b', 'foo', 'c', {3});
        p.a('bar');
        p.b({'baz' 'qux'});
        p.c([12 32]);
        
        assertEquals('bar',         p.a());
        assertEquals({'baz' 'qux'},   p.b());
        assertEquals([12 32],       p.c());
    end


    function testPropertyInheritance
        function this = TestObject
            this = inherit(properties('value', 1), public(@increment));
            
            function increment
                this.value(this.value() + 1);
            end
        end
        
        a = TestObject();
        
        assertEquals(a.value(), 1);
        a.increment();
        assertEquals(a.value(), 2);
        a.increment();
        assertEquals(a.value(), 3);
    end


    function testPropertyOverride
        %Shows how to override the property accessors made by
        %properties().
        function this = TestObject
            %p_ will contain a reference to the properties methods before 
            %overriding
            [this, p_] = inherit(...
                properties('a', 1, 'b', 2),...
                public(@b, @sum)...
            );
        
            function val = b(val)
                %override the property accessor so that
                %b gets rounded to integers
                
                %note i find checking nargin to be distateful, and would
                %like a better convention for getting/setting.
                if nargin > 0
                    p_.b(round(val));
                else
                    val = p_.b(); %_0 suffix accesses the non-overridden
                    %method.
                end
            end
            
            function s = sum()
                s = this.a() + this.b();
            end
        end
        
        o = TestObject();
        assertEquals(o.a(), 1);
        assertEquals(o.b(), 2);
        assertEquals(o.sum(), 3);
        
        %set a and b, but b gets rounded
        o.a(2.25);
        o.b(3.75);
        
        assertEquals(2.25, o.a());
        assertEquals(4, o.b());
        assertEquals(o.sum(), 6.25);
    end


    function testReferenceBehavior
        p = properties('a', 1, 'b', 2);
        
        assertEquals(1, p.a());
        assertEquals(2, p.b());
        increment_b(p);
        assertEquals(3, p.b());
    end


    function increment_b(props)
        props.b(props.b() + 1);
    end

end