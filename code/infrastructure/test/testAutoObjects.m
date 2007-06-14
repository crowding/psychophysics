function this = testAutoObjects()
    
    this = inherit...
        ( TestCase() ...
        , public ...
            ( @testAutoSetters ...
            , @testAutoGetters ...
            , @testAutoProperties ...
            , @testAutoRoundTrip ...
            , @testAutoPropsExcludesUnderscoreAndVarargin ...
            , @testVarargin ...
            , @testBadVarargin ...
            , @testAutoMethods ...
            , @testAutoMethodsExcludesUnderscore ...
            , @testOverrideSetter ...
            , @testOverrideGetter ...
            ) ...
        );
    
    
    function testAutoSetters()
        function [this, getter] = obj()
            propA = 1;
            this = autoprops();
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


    function testAutoGetters()
        function [this, setter] = obj()
            
            propA = 1;

            this = autoprops(); %the call to autoProps must happen AFTER all variables...

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
            this = autoprops();
        end
        
        o = obj();
        
        assertEquals(1, o.property__('propA'));
        o.property__('propA', 6);
        assertEquals(6, o.property__('propA'));
        assertEquals(6, o.getPropA());
    end


    function testAutoPropsExcludesUnderscoreAndVarargin()
        function this = obj(varargin)
            propA = 1;
            propB_ = 2;
            this = autoprops();
        end
        
        o = obj();
        assertEquals(1, o.getPropA());
        assertEquals(1, o.property__('propA'));
        assert(~isfield('getPropB_', o));
        assert(~isfield('setPropB_', o));
        assert(~isfield('getPropB', o));
        assert(~isfield('setPropB', o));
        assert(~isfield('varargin', o));
        
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
    end


    function testAutoRoundTrip()
        function this = obj()
            propA = 1;
            this = autoprops();
        end

        o = obj();
        
        assertEquals(1, o.getPropA());
        o.setPropA(4);
        assertEquals(4, o.getPropA());
    end


    function testVarargin()
        function this = obj(varargin)
            propA = 1;
            this = autoprops(varargin{:});
        end
        
        o = obj('propA', 3);
        assertEquals(3, o.getPropA());
    end


    function testBadVarargin()
        function this = obj(varargin)
            propA = 1;
            this = autoprops(varargin{:});
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
            this = automethods();
            
            function f = foobar()
                 f = 5;
            end
        end
        
        o = obj();
        assertEquals(5, o.foobar());
    end


    function testAutoMethodsExcludesUnderscore()
        function this = obj()
            this = automethods();
            
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
            
            this = inherit(autoprops(), automethods());
            
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
            
            this = inherit(autoprops(), automethods());
            
            function n = getTestProp(n)
                n = testProp + 1;
            end
        end
        
        o = obj();
        
        o.setTestProp(4);
        assertEquals(5, o.getTestProp());
    end
    
end