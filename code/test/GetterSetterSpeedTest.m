function this = GetterSetterSpeedTest

    disp('heritable object');
    function this = obj1(varargin)
        a = 1;
        this = inherit(autoprops(varargin{:}), automethods());
    end
    o = obj1();
    testSpeed();
    
    disp('final object')
    function this = obj2(varargin)
        a = 1;
        this = finalize(inherit(autoprops(varargin{:}), automethods()));
    end
    o = obj2();
    testSpeed();
    
    disp('final and implemented')
    function this = obj3(varargin)
        a = 1;
        this = finalize(inherit(autoprops(varargin{:}), automethods));
        
        function value = getA()
            value = a;
        end
        
        function value = setA(value)
            a = value;
        end
    end
    o = obj3();
    testSpeed();
    
    disp('non-auto, final')
    function this = obj4(varargin)
        a = 1;
        this = final(@getA, @setA);
        
        function value = getA()
            value = a;
        end
        
        function value = setA(value)
            a = value;
        end
    end
    o = obj4();
    testSpeed();
    
    disp('auto combined')
    function this = obj5(varargin)
        a = 1;
        this = autoobject();
    end
    o = obj5();
    testSpeed();
    
    
    function testSpeed()
        c = cputime();
        for i = 1:2000
            o.getA();
        end
        c = cputime() - c;
        printf('getting: %f s', c);

        c = cputime();
        for i = 1:2000
            o.setA(rand());
        end
        c = cputime() - c;
        printf('setting: %f s', c);
    end
end