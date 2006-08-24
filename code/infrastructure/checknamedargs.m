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
                error('namedargs:notPaired', 'arguments must com in name/value pairs');
            elseif isempty(regexp(arg, '^[A-Za-z][A-Za-z0-9_]{0,62}$', 'once'))
                error('namedargs:badName', '''%s'' is not a valid argument name', arg);
            end
            
            skip=1; %skip the next argument

        case 'struct'
            if ~isscalar(arg)
                error('namedargs:structArray', 'Nonscalar struct arrays as named arguments ar not permitted.')
            end
        otherwise
            error('namedargs:badArgumentType', 'Bad argument type for named arugments.')
    end
end