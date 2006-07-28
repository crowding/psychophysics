function pass = testClosures
    %demonstrates the presence of something idempotent to
    %closures in MATLAB R14.
    
    %create three closures (function handles) into one
    %lexical context:
    [x0, y0, get0] = makeClosure(0, 0);
    
    %and three closures with another lexical context:
    [x1, y1, get1] = makeClosure(100, 100);
   
    %The values contained in each closure can be modified independently:
    
    %the 'get' functions are bound to distinct variable contexts:
    assertEquals([0 0], get0());
    assertEquals([100 100], get1());
    
    %those variable contexts can be assigned to:
    x0(); x0();
    assertEquals([2 0], get0());
    
    y1(); y1();
    assertEquals([100 102], get1());
    
    %The function handles returned from makeClosure refer
    %to and modify the same closure.
    y0(); y0(); y0();
    assertEquals([2 3], get0());
    
    x1(); x1(); x1();
    assertEquals([103 102], get1());
    
    %the kicker: these function handles carry REFERENCES
    % to their mutable workspaces, and the workspaces do not copy-on-write
    % either when assigned to a new variable, or passed to a new argument
    xx0 = x0; %copy the 'object' -- does NOT copy the bound variables
    xx0(); xx0(); %modify data through a copied handle
    assertEquals([4 3], get0())
    
    callThreeTimes(y1); %pass closure to another function - it carries a
    %reference to the bound variabels
    assertEquals([103 105], get1());
    
    %all tests passed
    pass = 1;
    return;
    
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
         
        function incx
            x = x + 1;
        end
        
        function incy
             y = y + 1;
        end
        
        function state = get
            %construction of an anonymous function, requiring
            %at least one output?
            state = [x, y];
        end
    end
    
    function assertEquals(a, b)
        if ~all(a == b)
            if isa(a, 'numeric') && isa(b, 'numeric')
                error('assert:assertEquals', ...
                    strcat(...
                        'Expected ', mat2str(a), ...
                        ', got ', mat2str(b)));
            else
                error('assert:assertEquals', ...
                    'expected equal arguments, got different');
            end 
        end
    end
end