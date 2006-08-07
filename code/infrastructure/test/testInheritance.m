function this = testInheritance

this = public(...
    @testNonOverride...
    ,@testOverride...
    ,@testDelegateToParent...
    ,@testDelegateToChild...
    ,@testDelegateToParentToOverridingChild...
    ,@testOverrideDelegates...
    ,@testDelegateToGrandparent...
    ,@testDelegateToGrandchild...
    ,@testDelegateToGrandparentToGrandchild...
    );

    function this = Parent
        this = public(...
            @bar...
            ,@foo...
            ,@quux...
            ,@boffo...
            ,@yip...
            ,@gravorsh... %note declaration (used in yip), but definition not necessary
            );

        function r = foo
            r = 'Parent';
        end

        function r = bar
            r = 'Parent';
        end

        function r = quux
            r = this.bar();
        end
        
        function r = boffo
            r = 'Parent';
        end
        
        function r = yip
            r = this.gravorsh();
        end
    end

    function this = Child
        parent_ = Parent();
        this = inherit(...
            parent_...
            ,public(...
                @bar... %override bar
                ,@baz... %qux calls parent
                ,@quuux...
                ,@boffo...
                )...
            );

        function r = bar
            r = 'Child';
        end

        function r = baz
            r = this.foo();
        end

        function r = quuux
            r = this.quux();
        end
        
        function r = boffo
            %how to delegate to a parent - the _0 suffix
            r = [this.boffo_0() ' + Child'];
        end
        
    end

    function this = Grandchild
        this = inherit(...
            Child()...
            ,public(...
                @gravorsh...
                ,@flurbl...
                )...
            );
        
        function r = gravorsh
            r = 'Grandchild';
        end
        
        function r = flurbl
            r = this.yip();
        end
    end

    function testNonOverride
        c = Child();
        assertEquals('Parent', c.foo());
    end

    function testOverride
        c = Child;
        assertEquals('Child', c.bar());
    end

    function testDelegateToParent
        c = Child();
        assertEquals('Parent', c.baz())
    end

    function testDelegateToChild
        c = Child();
        assertEquals('Child', c.quux());
    end

    function testDelegateToParentToOverridingChild
        %Pay attention, this is a test that matlab's objects fail entirely
        c = Child();
        assertEquals('Child', c.quuux());
    end

    function testOverrideDelegates
        %when you override a method in your ancestor, the old method gets
        %renamed as methodname_0 and remains accessible to you that way.
        c = Child();
        assertEquals('Parent + Child', c.boffo());
    end

    function testDelegateToGrandparent
        g = Grandchild();
        assertEquals('Parent', g.foo());
    end

    function testDelegateToGrandchild
        g = Grandchild();
        assertEquals('Grandchild', g.gravorsh());
        
    end

    function testDelegateToGrandparentToGrandchild
        g = Grandchild();
        assertEquals('Grandchild', g.flurbl());
    end
end