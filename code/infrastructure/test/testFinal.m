function this = testFinal
%tests the creation of 'final' objects (basic ones, that can not be
%inherited

%create myself the hard way, this time
this = struct(...
    'setUp', @noop...
    ,'tearDown', @noop...
    ,'testMethodNaming', @testMethodNaming...
    ,'testVersion', @testVersion...
    ,'testMethod', @testMethod...
    ,'method__', @method__...
    );

    function noop
    end

    function val = method__(name, val);
        switch nargin
            case 0
                val = {'setUp', 'tearDown', 'testMethodNaming', 'testVersion', 'testMethod'};
            case 1
                this.(name) = val;
            otherwise
                val = this.(name);
        end
    end

    function testMethod
        testobj = myobj();
        assertEquals({'testfun'}, testobj.method__());
        fun = functions(testobj.method__('testfun'));
        assertEquals('testFinal/myobj/testfun', fun.function);
        try
            testobj.method('testfun', @sin);
            fail('expected error');
        end
    end

    function testMethodNaming
        testobj = myobj();
        fn1 = functions(testobj.testfun);

        assertEquals('testFinal/myobj/testfun', fn1.function);
    end

    function this = myobj()
        this = final(@testfun);
        
        function testfun
        end
    end

    function testVersion
        %all objects get a version__ field that gives the SVN path, function
        %name, and SVN version number of the file creating the object.
        
        obj = myobj();
        vers = obj.version__;
        
        %we make sure the info I am reporting matches the auto-substituted
        %info (SVN junk...)
        fninfo = functions(@myobj);
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
end