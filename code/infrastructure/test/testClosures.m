function this = testClosures

this = inherit(TestCase(),...
    public(@setUp, @tearDown...
    ,@testSeparateContexts...
    ,@testContextModification...
    ,@testMultipleHandlesOneContext...
    ,@testCopyReferenceBehavior...
    ,@testPassingReferenceBehavior...
    ,@testClosureSavesState...
    ,@testLoadDoesNotReattachToLiveContext...
    ,@testLoadReattachesToItself...
    ,@testSeparateVariablesReattach...
    ,@testGrabHandleToSelf...
    ,@testGrabParentHandleByEvalInCaller...
    ,@testCantGrabGrandparentHandleByTwoEvalsInCaller...
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

    function testClosureSavesState
        %the state of a closure is written to files
        
        x0(); x0(); %create some state
        
        fname = tempname();
        save(fname, 'get0');
        in = load([fname '.mat']);
        
        assertEquals(get0(), in.get0());
    end

    function testLoadDoesNotReattachToLiveContext
        %I would like for funcitons to re-attach to their contexts when
        %loaded and saved in an atomic operation.

        x0(); x0(); %create some state
        
        fname = tempname();
        save(fname, 'x0');
        in = load([fname '.mat']);
        
        assertEquals(3, x0());
        assertEquals(3, in.x0()); %in.x0() was not affected by x0()
        assertEquals(4, x0()); %and vice versa
    end

    function testLoadReattachesToItself
        %how about two closures saved and loaded in one operation?
        out = struct('x0', x0, 'y0', y0, 'get0', get0);
        
        fname = tempname();
        save(fname, '-struct', 'out');
        in = load([fname '.mat']);
        
        assertEquals(in.get0(), [0 0]);
        in.x0(); %alter state
        %does get0 see the same at x0 when loaded?
        assertEquals(in.get0(), [1 0]);
    end

    function testSeparateVariablesReattach
        %separate variables will re-attach on load if they were saved and
        %loaded in the same operation 
        
        fname = tempname();
        save(fname, 'x0', 'y0', 'get0');
        in = load([fname '.mat']);
        
        assertEquals(in.get0(), [0 0]);
        assertEquals(in.x0(), 1);
        assertEquals(in.y0(), 1);
        assertEquals(in.get0(), [1 1]);
    end

    function testGrabHandleToSelf
        a = 1;
        
        function [out, handle] = grabSelfHandle
            a = a + 1;
            out = a;
            handle = @grabSelfHandle;
        end
        
        [tmp2, handle] = grabSelfHandle();
        assertEquals(2, tmp2);

        [tmp3, handle] = handle();
        assertEquals(3, tmp3);
        
        [tmp4, handle] = handle();
        assertEquals(4, tmp4);
        
        assertEquals(a, 4);
    end

    function testGrabParentHandleByEvalInCaller
        a = 1;
        
        function [out, handle] = grabSelfHandle
            a = a + 1;
            out = a;
            
            handle = getParentHandle();
        end

        [tmp2, handle] = grabSelfHandle();
        assertEquals(2, tmp2);

        [tmp3, handle] = handle();
        assertEquals(3, tmp3);

        [tmp4, handle] = handle();
        assertEquals(4, tmp4);

        assertEquals(a, 4);
    end

    function h = getParentHandle()
        h = evalin('caller', '@()@grabSelfHandle');
        h = h();
    end

    function testCantGrabGrandparentHandleByTwoEvalsInCaller
        a = 1;
        function [out, handle] = grabSelfHandle
            a = a + 1;
            out = a;
            
            handle = getParentHandle();
            function h = getParentHandle()
                h = getGrandparentHandle();
            end 
        end
        
        [tmp2, handle] = grabSelfHandle();
        assertEquals(2, tmp2);

        %we won't be able to find the function
        try
            [tmp3, handle] = handle();
            fail()
        catch
            assertLastError('MATLAB:UndefinedFunction');
        end
    end

    function h = getGrandparentHandle
        h = evalin('caller', 'evalin(''caller'', ''@()@grabSelfHandle'')');
        h = h();
    end

%{
    function self = create_object
        stk = dbstack('-completenames');
        mname = stk(2).file;
        fcn_names = scan(mname, {'test[A-Za-z0-9_]*'});
        fcns = evalin('caller',['@(){' sprintf('@%s ', fcn_names{:}) '}']);
        fcns = fcns();
        for i = 1:length(fcns);fcn = fcns{i};
            self.(fcn_names{i}) = fcn;
        end
    end

    function names = scan(fname, patterns)

        if iscell(patterns)
            patterns = sprintf('(%s)|',patterns{:});
        end
        str = evalc(sprintf('mlint(''-calls'',''%s'')', fname));
        names = regexp(str,'\d+\s*([AZa-z][A-Za-z0-9_]*)','tokens');
        names = cellfun(@(x) x{1}, names, 'uniformoutput', false);
        i = cellfun(@(x)~isempty(regexp(x, patterns)), names);
        names = names(i);
    end
%}



        
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
