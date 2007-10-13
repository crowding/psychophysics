function link = linkfunction(fn, text)
    %produce an HTML link with the specified text, which when clicked
    %calls the given function.
    %
    %Example:
    %
    %disp(linkfunction(@(x)disp('hello world'), 'click here'));
    %
    %will, when run, print a link; clicking this link prints 'hello world.'
    persistent store;
    if isempty(store)
        store = struct();
    end
    
    %if called with only a text first argument, calls the function...
    if isa(fn, 'char')
        if isfield(store, fn)
            store.(fn)();
        else
            error('linkfunction:notFound', 'Linked function not found; possibly expired');
        end
    else
        [tmp, nm] = fileparts(tempname); %#ok
        store.(nm) = fn;
        link = sprintf('<a href="matlab:linkfunction(''%s'')">%s</a>',nm, text);
    end
end