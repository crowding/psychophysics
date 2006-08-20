function testObjectSpeed
%tests the speed of various ways of making a reference object with named
%setter, getter methods

profile on
foobar()
    function o = foobar()
        o = teststruct;
        o = testoldschool; %to be made with matlab 5 objects
        o = testprimitive;
        o = testintermediate;
        o = testfancy;
        o = testsuperfancy;
    end
profile viewer


    function obj = testsuperfancy
        obj = superfancytestobj(0);
        for i = 1:20000
            obj.setProp(obj.prop() + obj.fun());
        end
    end

    function obj = testfancy
        obj = fancytestobj(0);
        for i = 1:20000
            obj.setProp(obj.prop() + obj.fun());
        end
    end

    function obj = testintermediate
        obj = intermediatetestobj(0);
        for i = 1:20000
            obj.setProp(obj.prop() + obj.fun());
        end
    end

    function obj = testprimitive
        obj = primitivetestobj(0);
        for i = 1:20000
            obj.setProp(obj.prop() + obj.fun());
        end
    end

    function s = teststruct
        s = struct('prop', 0, 'val', 0);
        for i = 1:20000
            v = s.val;
            s.val = v + 1;
            s.prop = s.prop + v;
        end
    end

    function obj = testoldschool
        obj = OldSchool(0);
        for i = 1:20000
            %note how equivalent effects are more awkward, needing two
            %statements...
            [obj, f] = fun(obj);
            obj = setProp(obj, prop(obj) + f);
        end
    end



    function this = superfancytestobj(val_)
        this = inherit(...
            properties('prop', 0, 'val', val_),...
            public(@fun)...
            );

        function val = fun()
            val = this.setVal(this.val() + 1);
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

%objects can be made faster by including a boilerplate version of method()?
    function this = intermediatetestobj(val_)

        this = final(@fun);
        %boilerplate
        this.method__ = @method__;
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

    function this = primitivetestobj(val_)
        prop_ = 0;

        this = final(@prop, @setProp, @fun);

        function v = prop()
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