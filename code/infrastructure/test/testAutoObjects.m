function this = testAutoObjects()
    
    this = inherit...
        ( TestCase() ...
        , public ...
            ( @testAutoSetters ...
            , @testAutoSetV ...
            , @testAutoGetters ...
            , @testAutoProperties ...
            , @testAutoRoundTrip ...
            , @testNoAutoProperties...
            , @testAutoObjectExcludesUnderscoreAnsAndVarargin ...
            , @testAutoObjectVarsDefinedBefore ...
            , @testAutoObjectVarsUndefined ...
            , @testVarargin ...
            , @testBadVarargin ...
            , @testAutoMethods ...
            , @testAutoMethodsExcludesUnderscore ...
            , @testNoAutoMethods ...
            , @testOverrideSetter ...
            , @testOverrideGetter ...
            ) ...
        );
    
    
    function testAutoSetters()
        function [this, getter] = obj()
            propA = 1;
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
            this = autoobject();
        end
        
        o = obj();
        
        assertEquals(1, o.property__('propA'));
        o.property__('propA', 6);
        assertEquals(6, o.property__('propA'));
        assertEquals(6, o.getPropA());
    end

    function testNoAutoProperties()
        function this = obj()
            this = autoobject();
        end
        
        o = obj();
        
        assert(isempty(o.property__()));
    end


    function testAutoObjectExcludesUnderscoreAnsAndVarargin()
        function this = obj(varargin)
            propB_ = 2;
            propA = 1;
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
            o.property__('propB');
            fail();
        catch
        end
        
        try
            o.property__('varargin');
            fail();
        catch
        end
        
        try
            o.property__('ans');
            fail();
        catch
        end
    end

    function testAutoObjectVarsDefinedBefore()
        %Only gets variables that have been defined before the call to make
        %an object.
        function this = obj(varargin)
            propA = 1;
            this = autoobject(varargin{:});
            propB = 2;
        end
        
        o = obj();
        assertEquals(1, o.getPropA());
        assertEquals(1, o.property__('propA'));
        vars = o.property__();
        assert(strmatch('propA', vars));
        assert(~strmatch('propB', vars))
        try
            o.getPropB();
            fail();
        catch
        end
    end

    function testAutoObjectVarsUndefined()
        %Doesn't grab variables that are undefined (!)
        function this = obj(propA, varargin)
            this = autoobject(varargin{:});
        end
        
        o1 = obj();
        o2 = obj(1);
        try
            o1.getPropA()
        catch
        end
        assertEquals(1, o2.getPropA())
        
        assert(~strmatch('propA', o1.property__()));
        assert(strmatch('propA', o2.property__()));
        
        try
            o1.property__('propA');
            fail();
        catch
        end
        assertEquals(1, o2.property__('propA'));
    end

    function testAutoRoundTrip()
        function this = obj()
            propA = 1;
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
            this = autoobject(varargin{:});
        end
        
        o = obj('propA', 3);
        assertEquals(3, o.getPropA());
    end


    function testBadVarargin()
        function this = obj(varargin)
            propA = 1;
            this = autoobject(varargin{:});
        end
        
        try
            o = obj('propB', 2);
            fail();
        catch
            %expected
        end
    end

    
    function testAutoMethods()
        function this = obj()
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
            this = autoobject();
        end
        
        o = obj();
        assert(isempty(o.method__()));
    end

    function testAutoMethodsExcludesUnderscore()
        function this = obj()
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
        try
            o.baz_()
            fail();
        catch
        end
        
        try
            o.baz()
            fail();
        catch
        end
    end


    function testOverrideSetter
        function this = obj()
            testProp = 3;
            
            %this = inherit(autoobject(), autoobject());
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
            this = autoobject();
            
            function n = getTestProp(n)
                n = testProp + 1;
            end
        end
        
        o = obj();
        
        o.setTestProp(4);
        assertEquals(5, o.getTestProp());
    end
    
end