function this = testAutoObjects(varargin)
    
    %sketchy to define a test case in terms of this thing it's testing...
    this = inherit...
        ( TestCase()...
        , autoobject(varargin{:}) );
    
    function testAutoSetters()
        function [this, getter] = obj()
            propA = 1;
            persistent init__;
            this = autoobject();
            getter = @get;

            
            function a = get()
                a = propA;
            end
        end
        
        [o, get] = obj();
        assertEquals(1, get());
        o.setPropA(4);
        assertEquals(4, get());
    end

    function testAutoSetV()
        function [this, getter] = obj()
            v = 1;
            persistent init__;
            this = autoobject();
            getter = @get;

            function a = get()
                a = v;
            end
        end
        
        [o, get] = obj();
        assertEquals(1, get());
        o.setV(4);
        assertEquals(4, get());
    end


    function testAutoGetters()
        function [this, setter] = obj()
            
            propA = 1;

            persistent init__;
            this = autoobject(); %the call to autoobject must happen AFTER all variables...

            setter = @set;

            function set(x)
                propA = x;
            end
        end
        
        [o, set] = obj();
        assertEquals(1, o.getPropA());
        set(4);
        assertEquals(4, o.getPropA());
    end


    function testAutoProperties()
        function this = obj();
            propA = 1;
            persistent init__;
            this = autoobject();
        end
        
        o = obj();
        
        assertEquals(1, o.property__('propA'));
        o.property__('propA', 6);
        assertEquals(6, o.property__('propA'));
        assertEquals(6, o.getPropA());
    end

    function testPropertySubscript()
        its = Genitive();
        
        function this = objA(varargin)
            propA = 1;
            persistent init__;
            this = autoobject(varargin{:});
        end

        o = objA('propA');
        
        assertEquals(1, o.property__(its.propA));
        o.property__(its.propA, 4);
        assertEquals(4, o.property__(its.propA));
        assertEquals(4, o.getPropA());
    end

    function testPropertyRecursive()
        
        function this = objA(varargin)
            propA = 1;
            persistent init__;
            this = autoobject(varargin{:});
        end

        function this = objB(varargin)
            propB = 1;
            persistent init__;
            this = autoobject(varargin{:});
        end
        
        o = objA('propA', objB());
        
        assertEquals(1, o.property__('propA.propB'));
        o.property__('propA.propB', 4);
        assertEquals(4, o.property__('propA.propB'));
        
        a = o.getPropA();
        assertEquals(4, a.getPropB());
    end

    function testNoAutoProperties()
        function this = obj()
            persistent init__;
            this = autoobject();
        end
        
        o = obj();
        
        assert(isempty(o.property__()));
    end


    function testAutoObjectExcludesUnderscoreAnsAndVarargin()
        function this = obj(varargin)
            propB_ = 2;
            propA = 1;
            persistent init__;
            this = autoobject();
        end
        
        o = obj();
        assertEquals(1, o.getPropA());
        assertEquals(1, o.property__('propA'));
        assert(~isfield('getPropB_', o));
        assert(~isfield('setPropB_', o));
        assert(~isfield('getPropB', o));
        assert(~isfield('setPropB', o));
        assert(~isfield('getVarargin', o));
        assert(~isfield('setVarargin', o));
        assert(~isfield('getAns', o));
        assert(~isfield('setAns', o));
        
        try
            o.property__('propB_');
            error('err:expectedException', 'whoops');
        catch
            assertLastErrorNot('err:expectedException');
        end

        try
            o.property__('propB');
            error('err:expectedException', 'whoops');
        catch
            assertLastErrorNot('err:expectedException');
        end
        
        try
            o.property__('varargin');
            error('err:expectedException', 'whoops');
        catch
            assertLastErrorNot('err:expectedException');
        end
        
        try
            o.property__('ans');
            error('err:expectedException', 'whoops');
        catch
            assertLastErrorNot('err:expectedException');
        end
    end

    function testAutoObjectVarsDefinedAfter()
        %We don't grab variables that are defined after.
        %We used to, but Matlab changes its who()behavior and now we don't.
        function this = obj(varargin)
            %at first the test was written to assert that propB
            propA = 1;
            persistent init__;
            this = autoobject(varargin{:});
            
            %And in a changed version of matlab, I found I had to but this
            %here or propB wouldn't make it..
            function r = w()
                r = 0;
            end
            %aaaand as of r2010b, that still fails. Not much
            %can do about it, other than reverse the sense of the unit test
            propB = 2;
        end
        
        o = obj();
        assertEquals(1, o.getPropA());
        vars = o.property__();
        assert(~isempty(strmatch('propA', vars, 'exact'))); %one is true, unless you're suddenly a fan of strong typing like nowhere else in the language.
        assert(isempty(strmatch('propB', vars, 'exact')));
    end

    function testAutoObjectVarsUndefined()
        %Should grab variables that are undefined, if they come before the
        %call to autoobj.
        function this = obj(propA, varargin)
            persistent init__;
            this = autoobject(varargin{:});
        end
        
        o1 = obj();
        o2 = obj(1);
        assert(isfield(o1, 'getPropA'))
        o1.setPropA(2);
        assertEquals(2, o1.getPropA());
        assertEquals(1, o2.getPropA());
        
        assert(any(strcmp('propA', o1.property__())));
        assert(any(strcmp('propA', o2.property__())));
        
        o1.property__('propA');
        assertEquals(1, o2.property__('propA'));
    end

    function testAutoRoundTrip()
        function this = obj()
            propA = 1;
            persistent init__;
            this = autoobject();
        end

        o = obj();
        
        assertEquals(1, o.getPropA());
        o.setPropA(4);
        assertEquals(4, o.getPropA());
    end


    function testVarargin()
        function this = obj(varargin)
            propA = 1;
            persistent init__;
            this = autoobject(varargin{:});
        end
        
        o = obj('propA', 3);
        assertEquals(3, o.getPropA());
    end

    function testVararginSetMethod()
        function this = obj(varargin)
            propA = 1;
            persistent init__;
            this = autoobject(varargin{:});
            
            function setPropA(s)
                propA = s;
            end
        end
        
        o = obj('propA', 3);
        assertEquals(3, o.getPropA());
    end

    function testBadVarargin()
        
        %why does this overload the stack...
        function this = obj(varargin)
            propA = 1;
            persistent init__;
            this = autoobject(varargin{:});
        end
        
        try
            o = obj('propB', 2);
            error('err:expectedException', 'whoops');
        catch
            assertLastErrorNot('err:expectedException');
        end
    end
    
    function testAutoMethods()
        function this = obj()
            persistent init__;
            this = autoobject();
            
            function f = foobar()
                 f = 5;
            end
        end
        
        o = obj();
        assertEquals(5, o.foobar());
    end

    function testNoAutoMethods()
        function this = obj()
            persistent init__;
            this = autoobject();
        end
        
        o = obj();
        assert(isempty(o.method__()));
    end

    function testAutoMethodsExcludesUnderscore()
        function this = obj()
            persistent init__;
            this = autoobject();
            
            function f = baz_()
                f = 6;
            end
            
            function f = foobar()
                 f = 5;
            end
        end
        
        o = obj();
        assert(~isfield(o, 'baz_'));
        assert(~isfield(o, 'baz'));
    end


    function testOverrideSetter
        function this = obj()
            testProp = 3;
            
            %this = inherit(autoobject(), autoobject());
            persistent init__;
            this = autoobject();
            
            function setTestProp(n)
                testProp = n + 1;
            end
        end
        
        o = obj();
        
        o.setTestProp(4);
        assertEquals(5, o.getTestProp());
    end


    function testOverrideGetter
        function this = obj()
            testProp = 3;
            
            %this = inherit(autoobject(), autoobject());
            persistent init__;
            this = autoobject();
            
            function n = getTestProp(n)
                n = testProp + 1;
            end
        end
        
        o = obj();
        
        o.setTestProp(4);
        assertEquals(5, o.getTestProp());
    end
    
    function testDumpStruct
        function this = obj()
            propA = 3;
            propB = 4;
            
            persistent init__;
            this = autoobject();
            
            function setPropA(x)
                propA = x;
            end
            
            function b = getPropB()
                b = propB + 1;
            end
        end
        
        o = obj();
        
        [tmp, st] = o.property__(); %#ok
        assertIsEqual(struct('propA', 3, 'propB', 5), st);
    end

    function testCanonicalObject
        %the second output of 'method__()' returns the 'canonical' object
        %structure. Required for inheritance.
        
        function this = obj()
            
            propA = 3;
            
            persistent init__;
            this = autoobject();
            rmfield(this, 'getPropA');
        end
        
        o = obj();
        
        o = rmfield(o, 'getPropA');
        
        [methodnames, that] = o.method__(); %#ok

        assert(isfield(that, 'setPropA'));
        assert(isfield(that, 'getPropA'));
    end

    function testSetMethod()
        %basic requirement for inheritance. 'method__' with two arguments
        %sets 'this' INSIDE the method...
        
        function this = obj();
            
            propA = 3;
            
            persistent init__;
            this = autoobject();
            
            function test()
                assertEquals(this.foo, 'bar');
            end
        end
        
        o = obj();
        o.method__('foo', 'bar');
        o.test();
    end

    function testSetThis()
        function this = obj();
            
            propA = 3;
            
            persistent init__;
            this = autoobject();
            
            function test()
                assertEquals(this.foo, 'bar');
            end
        end

        o = obj();
        o.method__(struct('foo', 'bar'));
        o.test();
        [a, b] = o.method__();
        assertIsEqual(struct('foo', 'bar'), b);
    end

    function testDefaults()
        if defaults('exists', 'DefaultObject')
            defaults('remove', 'DefaultObject');
        end
        o = DefaultObject(); %as written, is 4
        assertIsEqual(o.getProp(), 4);
        
        defaults('set', 'DefaultObject', 'prop', 5);
        o = DefaultObject();
        assertIsEqual(o.getProp(), 5);
        
        o = DefaultObject('prop', 6);
        assertIsEqual(o.getProp(), 6);
        
        assertIsEqual(defaults('get', 'DefaultObject'), struct('prop', 5));
        defaults('remove', 'DefaultObject');
    end
end