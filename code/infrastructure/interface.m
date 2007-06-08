function [out, extra] = interface(prototype, in)
%Takes two structs. The second can be a cell array of structs.
%
%Extracts a subset of fields from the first struct so as to match the
%structure of the second struct.
%
%Useful when you will only be using a specific subset of an object, and you
%have a collection of them you are holding in an array and working with a
%lot. Extract the interface and you can use a struct array, which is faster
%than a cell array of structs.

    if iscell(in)
        [out, extra] = cellfun(@extract_interface, in, 'UniformOutput', 0);
        out = cell2mat(out);
    else
        [out, extra] = extract_interface(in);
    end

    function [out, extra] = extract_interface(s)
        names = fieldnames(prototype);
        extra = rmfield(s, names);
        out = rmfield(s, fieldnames(extra));
        out = orderfields(out, prototype);
    end

end

