function this = testFinal
%tests the creation of 'final' objects (basic ones, that can not be
%inherited

%create myself the hard way, for this once
this = struct(...
    'setUp', @noop...
    ,'tearDown', @noop...
    ,'testMethodNaming', @testMethodNaming...
    ,'testVersion', @testVersion...
    ,'method__', @method__...
    );

    function noop
    end

    function val = method__(name, val);
        if nargin > 1
            this.(name) = val;
        else
            val = this.(name);
        end
    end

    function testMethodNaming
        testobj = myobj()
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