function [out, extras] = interface(proto, in)
%Takes two structs. The second can be a cell array of structs.
%
%Extracts a subset of fields from the first struct so as to match the
%structure of the second struct.
%
%Useful when you will only be using a specific subset of an object, and you
%have a collection of them you are holding in an array and working with a
%lot. Extract the interface and you can use a struct array, which is faster
%than a cell array of structs.

%There used to be an elegant implentation of this here, but it fell victim
%to matlab's weirdness about making a deep copy of lexical variables every
%time you call a nested function. The weird thing about this weirdness is
%how difficult it is to isolate from the profiler.

    if ~iscell(in)
        in = {in};
    end
    
    fn = fieldnames(proto)';
    funcs = cell(size(fn));
    proto = fieldnames(proto);
    
    for i = 1:numel(fn);
        x = cell(size(in));
        for j = 1:numel(x)
            x{j} = in{j}.(fn{i});
        end
        funcs{i} = x;
    end
    
    args = {fn{:}; funcs{:}};
    out = struct(args{:});
    
    if nargout >= 2
        extras = cell(size(in));
        for i = i:numel(in);
            extras{i} = rmfield(in{i}, fn)
        end
    end
end