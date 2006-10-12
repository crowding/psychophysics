function o = namedargs(varargin)
%combine all given named arguments (scalar structs or named arugments)
%into a one struct

checknamedargs(varargin{:});
if (isstruct(varargin{1}) | isobject(varargin{1}))
    o = varargin{1};
    skip = 1;
else
    o = struct();
    skip = 0;
end

for i = 1:nargin
    if skip
        skip = 0;
        continue;
    end

    switch class(varargin{i})
        case 'char'
            %we support dotted strings to implicitly make substructs...
            subs = splitstr('.', varargin{i});
            value = varargin{i+1};
            
            value = makevalue(subs{2:end}, value);
            assign(subs{1}, value);
            skip=1; %skip the next argument
        case 'struct'
            for assignment = cat(2, fieldnames(varargin{i}), struct2cell(varargin{i}))'
                assign(assignment{:});
            end
        otherwise
            if isobject(varargin{i})
                for assignment = cat(2, fieldnames(varargin{i}), struct2cell(varargin{i}))'
                    assign(assignment{:});
                end
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

function out = makevalue(varargin)
    if (nargin > 1)
        out = struct(varargin{1}, makevalue(varargin{2:end}));
    else
        out = varargin{1};
    end
end