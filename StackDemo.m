function StackDemo()
    %demonstrates how nested function invocation is unacceptably slow.
    
    sizes = round(logspace(2, 3.2, 20));
        
    timesNested = zeros(size(sizes));
    timesPersistent = zeros(size(sizes));
    
    for i = 1:numel(sizes)
        disp(sizes(i));
        %time the nested stack -- how a stack would be implemented if its
        %speed was at all acceptable.
        timesNested(i) = testStack(@nestedStack, sizes(i), sizes(i));
        
        %What happens when the stack is stored in a persistent, instead of
        %externally scoped variable. This is unusable for general purposes
        %because now there can only be one stack at a time.
        timesPersistent(i) = testStack(@persistentStack, sizes(i), sizes(i));
    end
    
    %plot the results.
    plot(sizes, timesNested, 'r-', sizes, timesPersistent, 'b-');
    xlabel('Input size');
    ylabel('Execution time');
    legend('nested', 'persistent', 'Location', 'NorthWest');
    
end

function time = testStack(constructor, n, m)
    [push, pop, look] = constructor();
    a = cputime();
    for i = 1:n
        push(n);
        look();
    end
    for i = 1:m
        look();
        pop();
    end
    time = cputime() - a;
end

function [pushFn, popFn, lookFn] = nestedStack()
    %implement a stack using nested functions.
    stack = {};
    
    pushFn = @push;
    popFn = @pop;
    lookFn = @look;
    
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

    function what = look()
        what = stack{1};
    end

end

function [pushFn, popFn, lookFn] = persistentStack()
    %same as above ut the stack is in a persistent var. 
    %NO GOOD FOR ACTUAL USE since you cannot have more than one stack this way.
    
    persistent stack;
    
    pushFn = @push;
    popFn = @pop;
    lookFn = @look;
    
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

    function what = look()
        what = stack{1};
    end
end