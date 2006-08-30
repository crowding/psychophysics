function testObjectSpeed
%tests the speed of various ways of making a reference object with named
%setter, getter methods

profile on
foobar();
    function o = foobar()
        o = teststruct;
        o = testoldschool; %to be made with matlab 5 objects
        o = teststupidschool; %to be made with stupid-style matlab 5 objects
        o = testprimitive;
        o = testintermediate;
        o = testfancy;
        o = testsuperfancy;
        o = testwrapped;
    end
profile viewer



    function obj = testwrapped
        obj = wrappedtestobj(0);
        for i = 1:2000
            obj.prop = obj.prop + obj.fun();
        end
        obj.prop
    end

    function obj = testsuperfancy
        obj = superfancytestobj(0);
        for i = 1:2000
            obj.setProp(obj.getProp() + obj.fun());
        end
        obj.getProp()
    end

    function obj = testfancy
        obj = fancytestobj(0);
        for i = 1:2000
            obj.setProp(obj.getProp() + obj.fun());
        end
        obj.getProp()
    end

    function obj = testintermediate
        obj = intermediatetestobj(0);
        for i = 1:2000
            obj.setProp(obj.getProp() + obj.fun());
        end
        obj.getProp()
    end

    function obj = testprimitive
        obj = primitivetestobj(0);
        for i = 1:2000
            obj.setProp(obj.getProp() + obj.fun());
        end
        obj.getProp()
    end

    function obj = testoldschool
        obj = OldSchool(0);
        for i = 1:2000
            %note how equivalent effects are more awkward, needing two
            %statements...
            [obj, f] = fun(obj);
            obj = setProp(obj, getProp(obj) + f);
        end
        getProp(obj)
    end

    function obj = teststupidschool
        obj = StupidSchool(0);
        for i = 1:2000
            %this isw the way properties are "supposed" to be implemented
            %in matlab 5. Look how fucking awkward it is!
            [obj, f] = fun(obj);
            obj = set(obj, 'prop', get(obj, 'prop') + f);
        end
        get(obj, 'prop')
    end

    function s = teststruct
        s = struct('prop', 0, 'val', 0);
        for i = 1:2000
            v = s.val;
            s.val = v + 1;
            s.prop = s.prop + v;
        end
        s.prop
    end

%-----constructors-----

    function this = wrappedtestobj(n)
        this = Object(superfancytestobj(n));
    end

    function this = superfancytestobj(val_)
        this = inherit(...
            properties('prop', 0, 'val', val_),...
            public(@fun)...
            );

        function val = fun()
            val = this.getVal();
            this.setVal(val + 1);
        end
    end

    function this = fancytestobj(val_)
        this = inherit(...
            properties('prop', 0),...
            public(@fun)...
            );

        function val = fun()
            val = val_;
            val_ = val + 1;
        end

    end

%objects can be made faster by including a boilerplate version of method
%and thus losing a level of indirection?
    function this = intermediatetestobj(val_)

        this = final(@fun, @method__);
        
        %boilerplate
        function val = method__(name, val)
            if nargin > 1
                this.(name) = val;
            else
                val = this.(name);
            end
        end
        %/boilerplate
        
        this = inherit(this, properties('prop',0));

        function val = fun()
            val = val_;
            val_ = val_ + 1;
        end
    end

%faster still by doing it all manually?;
    function this = primitivetestobj(val_)
        prop_ = 0;

        this = final(@getProp, @setProp, @fun);

        function v = getProp()
            v = prop_;
        end

        function v = setProp(v)
            prop_ = v;
        end

        function v = fun()
            v = val_;
            val_ = v + 1;
        end
    end
end
