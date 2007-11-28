function this = testInheritance(varargin)

%persistent init__; %should have but don't...
this = inherit(TestCase(), autoobject(varargin{:}));

    function this = Parent(varargin);
        persistent init__;
        this = autoobject(varargin{:});

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
        
        function r = gravorsh()
        end
    end

    function this = Child
        persistent init__;
        this = autoobject(varargin);
        [this, parent_] = inherit(Parent(), this); %TODO make this just object()

        function r = bar
            r = 'Child';
        end

        function r = baz
            r = this.foo();
        end

        function r = quuux
            r = this.quux();
        end
        
        function r = grup
            r = this.flounce();
        end
        
        function r = flounce
            r = 'Child';
        end
        
        function r = boffo
            %how to delegate to a parent
            r = [parent_.boffo() ' + Child'];
        end
    end

    function this = Grandchild(varargin)
        persistent init__;
        this = inherit(Child(),autoobject(varargin{:}));
        
        function r = gravorsh
            r = 'Grandchild';
        end
        
        function r = flurbl
            r = this.yip();
        end
        
        function t = flounce
            t = 'Grandchild';
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

    function testParents
        %For inherited objects, you can call method__ with no arguments, and
        %the third argument out extracts the parent objects.
        %For non-inherited obejcts, the third output is am empty cell
        %array.
        
        obj = inherit(one, two);
        
        [tmp, tmp, p] = obj.method__();
        onep = p{1};
        twop = p{2};
        
        assertEquals(obj.bar(), 'two');
        assertEquals(onep.bar(), 'one');
        assertEquals(twop.bar(), 'two');
        
        function this = one(varargin)
            persistent init__;
            this = autoobject(varargin{:});
            
            function  v = foo
                v = 'one';
            end
            
            function v = bar
                v = 'one';
            end
        end
        
        function this = two
            persistent init__;
            this = autoobject(varargin{:});
            
            function v = bar
                v = 'two';
            end
            
            function v = baz
                v = 'two';
            end
        end
        
        non = two();
        [tmp, tmp, p] = non.method__();
        assertIsEqual({}, p);
    end

    function testPropertyMethod
        obj = inherit(a(), b());
        function this = a
            one = 1;
            two = 2;
            
            persistent init__;
            this = autoobject();
        end
        function this = b
            one = 100;
            three = 3;

            persistent init__;
            this = autoobject();
        end
        assertEquals({'one', 'three', 'two'}', sort(obj.property__()));
        assertEquals(100, obj.property__('one'));
        assertEquals(2, obj.property__('two'));
        assertEquals(3, obj.property__('three'));
        
        [tmp, st] = obj.property__();
        assertIsEqual(struct('one', 100, 'two', 2, 'three', 3), st);
        
        %now try setting properties
        obj.property__('one', 1000);
        obj.property__('two', 20);
        obj.property__('three', 30);

        assertEquals(1000, obj.property__('one'));
        assertEquals(20, obj.property__('two'));
        assertEquals(30, obj.property__('three'));

        assertEquals(1000, obj.getOne());
        assertEquals(20, obj.getTwo());
        assertEquals(30, obj.getThree());
        
        [tmp, st] = obj.property__();
        assertIsEqual(struct('one', 1000, 'two', 20, 'three', 30), st);
        
    end

    function testMethodMethod
        obj = Child();
        assertEquals(...
            sort({'bar','foo','quux','boffo','yip','gravorsh','baz','quuux','grup','flounce'}')...
            ,sort(obj.method__()) );

        %other characteristics of method__ are tested adequately by
        %inheritance exercises...
    end

    function testVersion
        %all objects get a version__ field that gives the SVN path, function
        %name, and SVN version number of the file creating the object.
        
        obj = Parent();
        vers = obj.version__;
        
        %we make sure the info I am reporting matches the auto-substituted
        %info (the 'url' and 'revision' lines below are auto-filled in by
        %SVN).
        fninfo = functions(@Parent);
        url = '$HeadURL$';
        revision = '$Revision$';
        
        %process down the url and revision here
        url = regexprep(url, '\$HeadURL: (.*) \$', '$1');
        revision = regexprep(revision, '\$Revision: (.*) \$', '$1');
        revision = str2num(revision);
        
        assertEquals(fninfo.function, vers.function);
        assertEquals(url, vers.url);
        assertEquals(revision, vers.revision);
        
        %was thinking about grabbing the handle, but when I'm dumping out
        %to text it doesn't make much sense.
        %h = functions(vers.handle);
        %assertEquals(fninfo.function, h.function);
    end

    function testGrandchildOverridesChild
        g = Grandchild();
        assertEquals('Grandchild', g.grup());
    end

    function testInheritObjects
        %you can inherit from object wrappers - the object wrapper-ness
        %gets stripped from the outermost object. calling object() again
        %puts it back.
        %fail('not written');
    end
        
end
