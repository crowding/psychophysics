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
    %
    %note, the way that MATLAB fails to trip and exception on Ctrl-c (or on
    %dbquit) is TOTALLY RETARDED and causes PAIN AND DEATH. Wham! All your
    %filehandles left open! Bam! All memory allocated in MEX extensions never
    %reclaimed. Poof! Now if you're on a single screen machine you get to
    %learn Cmd+0,"clear Screen" typing blind. Even better, this was a
    %deliberate decision and change from earlier reasonable behavior
    %according to Steven Lord.
    %
    %Interestingly, if you have 'dbstop if error' set, the debugger will
    %stop at a Ctrl-c. Not that you can trigger anything that way;
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
                warning('resourcecheck:missing', 'missing resource to back out!');
            else
                [oldstack] = resources{1}{1};
                [oldr] = resources{1}{2};
                if ~checkstack(oldstack, stack)
                    error('resourcecheck:unreleased', 'some resources were left open? Attempting to close...');
                    %resourcepanic(stack);
                else
                    %we are checking out..
                end
                resources = resources{2};
            end
            %fprintf('<<<popped %s\n', func2str(oldr));
        case 2
            resources = {{stack, release} resources};
            %fprintf('>>>pushed %s\n', func2str(release));
    end

    function r = checkstack(oldstack, newstack)
        if numel(oldstack) > numel(newstack)
            r = 0;
            return;
        end
        %vector indexing annoyance dsfargeg........
        %
        os = oldstack(2:end);
        ns = newstack(max(1, end-numel(oldstack)+2):end);
        r = isequal(os(:), ns(:));
        %add'ly check that we are in the same func at the top of oldstack.
        if r && ~isempty(os)
            r = isequal(oldstack(1).file, newstack(end-numel(oldstack)+1).file) ...
                && isequal(oldstack(1).name, newstack(end-numel(oldstack)+1).name) ;
        end
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