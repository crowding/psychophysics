function resourcecheck(stack, release)
    %The nature of resources is that a resource called on one stack frame
    %should be released before ending the stack frame.
    %Since there are ways in MATLAB to cancel execution without tripping
    %any exception handlers, there needs to be a post-hoc check to clean up
    %leftover resources
    %This is called with one arg before executing any initializer
    %function.
    %Then it is called with two args to add the stack and releaser to the
    %queue.
    %This is called with zero args just before we release, to remove it
    %form the stack (releasers should only be attempted once.)
    persistent resources;
    
    switch(nargin)
        case 0
            if isempty(resources)
                error('resourcecheck:missing', 'missing resource to back out!');
            else
                %check the stack anyway
                stack = dbstack();
                [oldstack] = resources{1}{1};
                if checkstack(oldstack, stack)
                    resources = resources{2};
                else
                    warning('resourcecheck:unreleased', 'some resources were left open');
                    resourcepanic(stack);
                end
            end
        case 1
            %check the stack
            if ~isempty(resources)
                [oldstack] = resources{1}{1};
                if ~checkstack(oldstack, stack)
                    warning('resourcecheck:unreleased', 'some resources were left open');
                    resourcepanic(stack);
                end
            end
        case 2
            resources = {{stack, release} resources};
    end

    function r = checkstack(oldstack, newstack)
        r = isequal(oldstack(2:end), newstack(max(1, end-numel(oldstack)+2):end));
    end
        
    function resourcepanic(stack)
        %Release EVERYTHING
        %
        %
        try
            resources{1}{2}();
        catch
            l = lasterror;
            try
                resources = resources{2};
                if ~isempty(resources)
                    resourcepanic(stack);
                end
            catch
                l = adderror(lasterror, l); %not strictly a cause, but an additional error...
            end
            rethrow(lasterror);
        end
        
        resources = resources{2};
        if ~isempty(resources)
            resourcepanic(stack);
        end
    end
end