function this = testLog

    this = inherit(TestCase(),...
        public(...
        @testLog...
        ,@testLogMessage...
        ,@testLogOrder...
        ,@testLogEnclosed...
        ,@testLogEnclosedWithError...
        ,@testLogObject...
        ));
        
    function testLog
        l = Logger();
        l.log(1,3,2);
        assertEquals({{1, 3, 2}}, l.getLog());
    end

    function testLogMessage
        l = Logger();
        l.logMessage('test %0.1f', 0.5);
        assertEquals({'test 0.5'}, l.getLog());
    end

    function testLogOrder
        l = Logger();
        l.log(1);
        l.log(2);
        assertEquals({{1}, {2}}, l.getLog());
    end

    function testLogEnclosed
        l = Logger();
        require(l.logEnclosed('MESSAGE %d', 1), @f)
        function f(params)
            params.log.logMessage('testing');
        end
        
        assertEquals({'BEGIN MESSAGE 1', 'testing', 'END MESSAGE 1'}, l.getLog());
    end

    function testLogEnclosedWithError()
        l = Logger();
        try
        require(l.logEnclosed('MESSAGE %d', 1), @f);
            fail('expected an error');
        catch
            %expect an error
        end
        function f(params)
            error('test:identifier', 'test error');
        end
        
        assertEquals({'BEGIN MESSAGE 1', 'ERROR test:identifier', 'END MESSAGE 1'}, l.getLog());
    end

    function testLogObj.m
        %an object or struct can be logged and composed of several
        %underlying things...?
        fail('test not written');
    end
end
