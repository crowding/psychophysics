function this = testPublic
    %tests the creation of 'public' objects (that can be inherited)
    
    %create myself using final
    this = final(@setUp, @tearDown, ...
        @testMethodNaming, @testVersion, ...
        @testMethodGetting, @testMethodSetting, @method__);
    
    function setUp
    end

    function tearDown
    end

    function testMethodNaming
        o = testobj();
        
        assertEquals('testobj', o.testfun());
        assertEquals('testobj', o.calltestfun());
    end

    function val = method__(name, val);
        if nargin > 1
            this.(name) = val;
        else
            val = this.(name);
        end
    end

    function testVersion
        %all objects get a version__ field that gives the SVN path, function
        %name, and SVN version number of the file creating the object.
        
        obj = testobj();
        vers = obj.version__;
        
        %we make sure the info I am reporting matches the auto-substituted
        %info (SVN junk...)
        fninfo = functions(@testobj);
        url = '$HeadURL$';
        revision = '$Revision$';
        
        %process down the url and revision here
        url = regexprep(url, '\$HeadURL: (.*) \$', '$1');
        revision = regexprep(revision, '\$Revision: (.*) \$', '$1');
        revision = str2num(revision);
        
        assertEquals(fninfo.function, vers.function);
        assertEquals(url, vers.url);
        assertEquals(revision, vers.revision);
    end

    function testMethodGetting
        o = testobj();
        
        objfn = functions(o.method__('testfun'));
        assertEquals('testPublic/testobj/testfun', objfn.function);

        objfn = functions(o.method__('calltestfun'));
        assertEquals('testPublic/testobj/calltestfun', objfn.function);

    end

    function testMethodSetting
        o = testobj();
        o.method__('testfun', @override);
        
        assertEquals('override', o.testfun());
        assertEquals('override', o.calltestfun());
        
        function v = override()
            v = 'override';
        end
    end
        
    function this = testobj
        this = public(@testfun, @calltestfun);
        prop = 4;
        
        function v = testfun
            v = 'testobj';
        end
        
        function r = calltestfun
            r = this.testfun();
        end
    end
end
