function [history, stacks, transitioncounts, transitiontimes] = checkpoint(maxframes)

%function [history, stacks, transitioncounts, transitiontimes] = checkpoint(maxframes)
%
%Collects a list of stack traces for hardcore performance profiling. When
%investigating a performance problem, place a call to checkpoint(1) in
%your code once to reset, then sprinkle a bunch of calls to checkpoint() in
%strategic places. Since it records the entire stack at each invocation,
%this deals better with recursion. (as opposed to matlab's profiler which
%gets very confused especially with function handles)
%
%Call with output arguments to process the data into a report. The outputs
%are:
%
%history          -- the time of each invocation and the index into the
%                    stacks array
%
%stacks           -- each unique stack that was seen
%
%transitioncounts -- count of transitions between the unique stacks (a square
%                    matrix)
%transitiontimes  -- total time spent in each transition (another sq. matrix)

persistent stack_;
persistent n_;
persistent maxframes_;

if isempty(stack_) || ((nargin >= 1))
    stack_ = {};
    n_ = 0;
    maxframes_ = maxframes;
end

if nargout >= 1
    %Here is how we compute the output extraction...
    stacks = {};
    s = stack_;
    history = zeros(n_, 2);
    for i = 1:n_
        time = s{1};
        stack = s{2};
        %which stack is it?
        found = 0;
        for j = 1:numel(stacks)
            if isequalwithequalnans(stack, stacks{j})
                found = 1;
                index = j;
                break;
            end
        end
        if ~found
            stacks = cat(1, {stack}, stacks);
            history(end-i+2:end,2) = history(end-i+2:end, 2) + 1;
            index = 1;
        end
        
        history(end-i+1,:) = [time, index];
        s = s{end};
    end
    
    transitioncounts = zeros(numel(stacks));
    transitiontimes = zeros(numel(stacks));
    
    for i = [history(1:end-1,:) history(2:end, :)]'
        transitioncounts(i(2), i(4)) = transitioncounts(i(2), i(4)) + 1;
        transitiontimes(i(2), i(4)) = transitiontimes(i(2), i(4)) + (i(3) - i(1));
    end
else
    %build a linked list...
    s = GetSecs();
    ds = dbstack();
    ds = ds(2:min(maxframes_+1,end));
    stack_ = {s ds stack_};
    n_ = n_ + 1;
end