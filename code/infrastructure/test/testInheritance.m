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
            ,@gravorsh...
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
        
        %FIXME - Unfortunately, you have to (for now) define functions you
        %call on yourself, evven if they are alwasy implemented by chlidren
        % - no abstract classes
        function r = gravorsh
            r = 'Parent';
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
            r = parent_.boffo()
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
        %You unfortunately can't call back to the parent method if you've
        %overridden it. It will overflow the stack because inheritance
        %(muddling) directly modifies the Use delegates instead. (God help you if you want to
        %both delegate and have your parent call back to you. Your objects
        %are too complicated.)
        try
            c = Child();
            %if I do manage to make it work...
            assertEquals('Child', c.boffo()); %what I would like it to do
            fail('should have crashed');
        catch
            assertLastError('MATLAB:recursionLimit');
        end
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