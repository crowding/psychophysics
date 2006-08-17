function this = testClosures

this = inherit(TestCase(),...
    public(@setUp, @tearDown...
    ,@testSeparateContexts...
    ,@testContextModification...
    ,@testMultipleHandlesOneContext...
    ,@testCopyReferenceBehavior...
    ,@testPassingReferenceBehavior...
    ));
    
    [x0, y0, get0, x1, y1, get1] = deal([]);

    %demonstrates the presence of something idempotent to
    %closures in MATLAB R14.
    
    function setUp
        %create three closures (function handles) into one
        %lexical context:
        [x0, y0, get0] = makeClosure(0, 0);

        %and three closures with another lexical context:
        [x1, y1, get1] = makeClosure(100, 100);
    end

    function tearDown
        [x0, y0, get0, x1, y1, get1] = deal([]);
    end

    function testSeparateContexts
        %the 'get' functions are bound to distinct variable contexts:
        assertEquals([0 0], get0());
        assertEquals([100 100], get1());
    end
    
    function testContextModification
        %those variable contexts can be modified, and remember their 
        %modifications:
        assertEquals(1, x0());
        assertEquals(2, x0());
    end
    
    function testMultipleHandlesOneContext
        %The function handles returned from makeClosure refer
        %to and modify the same closure.
        y0(); y0(); y0();
        assertEquals([0 3], get0());
    end
    
    function testCopyReferenceBehavior
        %the kicker: these function handles carry REFERENCES
        % to their mutable workspaces, and the workspaces do not copy-on-write
        % either when assigned to a new variable, or passed to a new argument
        xx0 = x0; %copy the 'object' -- does NOT copy the bound variables
        xx0(); xx0(); %modify data through a copied handle
        assertEquals([2 0], get0());
    end

    function testPassingReferenceBehavior
        callThreeTimes(y1); %pass closure to another function - it carries a
        %reference to the bound variabels
        assertEquals([100 103], get1());
    end

    function callThreeTimes(bork)
        bork(); bork(); bork();
    end    
    
    %this is the function that returns a closure
    function [xf, yf, getf] = makeClosure(the_x, the_y)
        %this function contains local variables x, y, and z
        %that are closed over
        x = the_x;
        y = the_y;
            
        %returning these functions
        xf = @incx;
        yf = @incy;
        getf = @get;
         
        function v = incx
            x = x + 1;
            v = x;
        end
        
        function v = incy
             y = y + 1;
             v = y;
        end
        
        function state = get
            %construction of an anonymous function, requiring
            %at least one output?
            state = [x, y];
        end
    end
    
end