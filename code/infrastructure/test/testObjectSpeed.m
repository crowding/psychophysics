function f = testObjectSpeed
profile on
testfancy;
testprimitive;
% testoldschool; %to be made with matlab 5 objects
profile viewer

    function testfancy
        obj = testobj(0);
        for i = 1:5000
            obj.prop(obj.prop() + obj.fun());
        end
    end

    function testprimitive
        obj2 = primitivetestobj(0);
        for i = 1:5000
            obj2.prop(obj2.prop() + obj2.fun());
        end
    end

    function this = testobj(val_)
        this = inherit(...
            properties('prop', 0),...
            public(@fun)...
            );

        function val = fun()
            val = val_;
            val_ = val_ + 1;
        end

    end

    %objects can be written faster by including a boilerplate function
    function this = primitivetestobj(val_)
        this = final(@fun);
        
        %boilerplate
        this.method__ = @method__;
        function val = method__(name, val);
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

end