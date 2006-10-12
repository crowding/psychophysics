function checknamedargs(varargin)

good = 1;

o = struct();
skip = 0;
n = nargin;

for i = 1:n
    if skip
        skip = 0;
        continue
    end
    
    arg = varargin{i};
    
    switch class(arg)
        case 'char'
            if n == i
                error('namedargs:notPaired', 'arguments must come in name/value pairs');
            elseif ~all(cellfun(@isvarname, splitstr('.',arg)))
                error('namedargs:badName', '''%s'' is not a valid argument name chain', arg);
            end
            
            skip=1; %skip the next argument

        case 'struct'
            if ~isscalar(arg)
                error('namedargs:structArray', 'Nonscalar struct arrays as named arguments are not permitted.')
            end
        otherwise
            if ~isobject(arg)
                error('namedargs:badArgumentType', 'Bad argument type for named arugments.')
            end
            if ~isscalar(arg)
                error('namedargs:objectArray', 'Nonscalar object arrays as named arguments are not permitted.')
            end
            
    end
end