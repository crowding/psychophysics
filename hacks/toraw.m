function [out, filters] = toraw(obj)
    % function dump(obj, printer, prefix)
    %
    %Converts an object to a raw struct for editing in the array editor.
    
    out = [];
    filters = cell(0, 2);
    
    visit(obj, @doAssign, @noteFilters);
    
    function doAssign(subs, what)
        if isempty(subs)
            out = what;
        else
            out = subsasgn(out, subs, what);
        end
    end

    function noteFilters(subs, what)
        %just note the subscripts and the filters in the order they
        %occurred.
        filters(end+1,:) = {subs, what};
    end
end

