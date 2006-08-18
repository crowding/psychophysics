function o = namedargs(varargin)
%combine all given named arguments (scalar structs or named arugments)
%into a one struct

checknamedargs(varargin{:});
o = struct();
skip = 0;

for i = 1:nargin
    if skip
        skip = 0;
        continue
    end
    
    switch class(varargin{i})
        case 'char'
            o.(varargin{i}) = varargin{i+1};
            skip=1; %skip the next argument
        case 'struct'
            for assignment = cat(2, fieldnames(varargin{i}), struct2cell(varargin{i}))';
                o.(assignment{1}) = assignment{2};
            end
    end
end