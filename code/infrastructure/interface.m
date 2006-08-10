function out = interface(in, prototype)
%Takes two structs The first can be a cell array of structs.
%
%Extracts a subset of fields from the first struct so as to match the
%structure of the second struct.
%
%Useful when you will only be using a specific subset of an object, and you
%have a collection of them you are holding in an array and working with a
%lot. Extract the interface and you can use a struct array, which is faster
%than a cell array.

if iscell(in)
    out = cellfun(@extract_interface, in);
else
    out = extract_interface(in);
end

    function substruct = extract_interface(s)
        names = fieldnames(prototype);

        values = cellfun(@extract_field, names, 'UniformOutput', 0);
        
        function val = extract_field(name)
            %here I have to again deal with matlab's bizarro wacko multiple function
            %outputs, only this time it's because you can't get all of one field of
            %a struct array directly.

            %requires knowledge of the number of args out,
            %which must be obtained by other means. Bah.
            val = cell(size(s));
            [val{:}] = s.(name);
        end

        args = cat(2, names, values)';
        substruct = struct(args{:});
    end

end

