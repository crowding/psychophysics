function StackDemo()
    %demonstrates how nested function invocation is unacceptably slow.
    
    sizes = round(logspace(2, 3.2, 20));
        
    timesNested = zeros(size(sizes));
    timesPersistent = zeros(size(sizes));
    timesGrow = zeros(size(sizes));
    
    for i = 1:numel(sizes)
        disp(sizes(i));

        %time the nested stack -- how a stack would be implemented if its
        %speed was at all acceptable.
        [push, pop] = nestedStack();
        timesNested(i) = testStack(push, pop, sizes(i), sizes(i));
        
        %What happens when the stack is stored in a persistent, instead of
        %externally scoped variable. This is unusable for general purposes
        %because now there can only be one stack at a time.
        [push, pop] = persistentStack();
        a = cputime();
        testStack(push, pop, sizes(i), 0);
        timesPersistent(i) = testStack(push, pop, sizes(i), sizes(i));
        
        %What happens when the stack is stored in a persistent, instead of
        %externally scoped variable. This is unusable for general purposes
        %because now there can only be one stack at a time.
        [push, pop] = growStack();
        timesGrow(i) = testStack(push, pop, sizes(i), sizes(i));
    end
    
    %plot the results.
    plot(sizes, timesNested, 'r-', sizes, timesPersistent, 'b-', sizes, timesGrow, 'g-');
    xlabel('Input size');
    ylabel('Execution time');
    legend('nested', 'persistent', 'growing', 'Location', 'NorthWest');
end

function [time, timePush, timePop] = testStack(push, pop, n, m)
    a = cputime();
    for i = 1:n
        push(n);
    end
    timePush = cputime() - a;
    for i = 1:m
        pop();
    end
    timePop = cputime() - a - timePush;
    time = timePush + timePop;
end

function [pushFn, popFn] = nestedStack()
    %implement a stack using nested functions.
    stack = {};
    
    pushFn = @push;
    popFn = @pop;
    
    function push(what)
        stack = {what stack};
    end

    function what = pop()
        if isempty(stack)
            what = [];
            stack = {};
        else
            what = stack{1};
            stack = stack{2};
        end
    end
end

function [pushFn, popFn] = growStack()
%implement a stack using nested functions.
stack = {};
pushFn = @push;
popFn = @pop;
    function push(what)
        stack = [what stack];
    end
    function what = pop()
        if isempty(stack)
            what = [];
            stack = {};
        else
            what = stack{1};
            stack = stack(2:end);
        end
    end
end

function [pushFn, popFn] = persistentStack()
    %same as above ut the stack is in a persistent var. 
    %NO GOOD FOR ACTUAL USE since you cannot have more than one stack this way.
    
    persistent stack;
    
    pushFn = @push;
    popFn = @pop;
    
    function push(what)
        stack = {what stack};
    end

    function what = pop()
        if isempty(stack)
            what = [];
            stack = {};
        else
            what = stack{1};
            stack = stack{2};
        end
    end
end