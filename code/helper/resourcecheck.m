function stack = resourcecheck(stack, release)
    %The nature of resources is that a resource called on one stack frame
    %should be released before ending the stack frame.
    %Since there are ways in MATLAB to cancel execution without tripping
    %any exception handlers, there needs to be a post-hoc check to clean up
    %leftover resources
    %This is called with zero args before executing any initializer
    %function.
    %Then it is called with two args to check in after running the
    %initializer.
    %Then it is called with one arg to check out.
    persistent resources;
    
    
    switch(nargin)
        case 0
            %disp ===checking
            stack = dbstack();
            stack = stack(3:end);
            if ~isempty(resources)
                %check the stack
                [oldstack] = resources{1}{1};
                if ~checkstack(oldstack, stack)
                    warning('resourcecheck:unreleased', 'some resources were left open. Attempting to close...');
                    resourcepanic(stack);
                end
            end
        case 1
            %check the stack
            if isempty(resources)
                error('resourcecheck:missing', 'missing resource to back out!');
            else
                [oldstack] = resources{1}{1};
                if ~checkstack(oldstack, stack)
                    error('resourcecheck:unreleased', 'some resources were left open? Attempting to close...');
                    %resourcepanic(stack);
                else
                    %we are checking out..
                end
                resources = resources{2};
            end
            %disp <<<popped
        case 2
            resources = {{stack, release} resources};
            %disp >>>pushed
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