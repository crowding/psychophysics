function o = namedargs(varargin)
%combine all given named arguments (scalar structs or named arugments)
%into a one struct

checknamedargs(varargin{:});
o = struct();
skip = 0;

for i = 1:nargin
    if skip
        skip = 0;
        continue;
    end

    switch class(varargin{i})
        case 'char'
            assign(varargin{i:i+1});
            skip=1; %skip the next argument
        case 'struct'
            for assignment = cat(2, fieldnames(varargin{i}), struct2cell(varargin{i}))'
                assign(assignment{:});
            end
    end
end

    function assign(field, value)

        if isfield(o, field) && isstruct(o.(field)) && isstruct(value)
            o.(field) = namedargs(o.(field), value);
        else
            o.(field) = value;
        end
    end

end