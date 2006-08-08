function this = assigninTest

this = final(...
    @testAssignIn...
    ,@testAssignStructIn...
    ,@testMakeFunctionIn...
    ,@testEvalAssignIn...
    ,@testAssignInClosure...
    ,@testAssignInAnonymous...
    );

    function testAssignIn
        loc = 1;
        assignInSub();
        assertEquals(2, loc);
    end

    function assignInSub
        assignin('caller', 'loc', 2);
    end

    function testAssignStructIn
        loc = struct('a', 1, 'b', 2);
        assignStructInSub();
        assertEquals(3, loc.b);
    end

    function assignStructInSub
        %evalin('caller', 'loc.b = 3;');
        %assignin('caller', 'loc.b', 3);
    end

    function testMakeFunctionIn
        foo = []; %must declare
        makeFunctionIn()
        assertEquals(5, foo());
    end

    function makeFunctionIn
        assignin('caller', 'foo', @() 5);
    end

    function testEvalAssignIn
        a = 0;
        b = 0;
        evalAssignIn();
        assertEquals(b, 1);
    end
    
    function evalAssignIn
        evalin('caller', '@slotassignin(''caller'', ''b'', 1)');
    end

    function testAssignInAnonymous
        %using assignin inside a closed-over function, you can 
        %
        
        [fn, check] = setup();
        fn('bar');
        assertEquals('bar', check());
        
        function [fn, check] = setup
            that = 'foo';
            %fn = @(val) assigninme('that', comma(that, val));
            fn = @setthat;
            
            check = @()that;
            
            function setthat(val)
                that = that;
                assigninme('that', comma(that, val));
            end
        end
        
        function val = ident(val)
        end
        
        function val = comma(that, val);
        end
        
        function assigninme(name, val)
            assignin('caller', name, val);
        end
    end
        
end

function val = slot(name, val)
    if (nargin < 3)
        this.(name) = val;
    else
        val = this.(name);
    end
end