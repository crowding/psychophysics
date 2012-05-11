function assertEquals(a, b, reltol)

if (nargin < 3)
    reltol = 0;
end

if ~strcmp(class(a), class(b))
    error('assert:assertEquals',...
        'arguments are of different classes (%s versus %s)',...
        class(a), class(b));
elseif ischar(a) && ~strcmp(a, b)
    error('assert:assertEquals', ...
        'unequal strings ("%s" versus "%s")', a, b);
elseif (ndims(a) ~= ndims(b))
    error('assert:assertEquals', ...
        'Arguments have different numbers of dimensions (%s versus %s)', ...
        mat2str(ndims(a)), mat2str(ndims(b)));
elseif (~all(size(a) == size(b)))

    error('assert:assertEquals', ...
        'Arguments are of unequal size (%s versus %s)', ...
        mat2str(size(a)), mat2str(size(b)));
elseif isobject(a) || isjava(a)
    error('assert:assertEquals', 'comparison not implemented on MATLAB or JAVA objects.');
else
    switch class(a)
        case 'cell'
            ass = @(a, b) assertEquals(a,b,reltol);
            cellfun(ass, a, b, 'ErrorHandler', @errorHandler);
        case 'struct'
            a = orderfields(a);
            b = orderfields(b);
            assertEquals(fieldnames(a), fieldnames(b), reltol);
            assertEquals(struct2cell(a), struct2cell(b), reltol);
        case 'function_handle'
            same = isequalwithequalnans(a, b);
            if ~same
                error('assert:assertEquals', 'function handles not equal');
            end
            %error('assert:assertEquals', ['function handle comparison '...
            %    'not implemented (possible infinite recursion)']);
            %assertEquals(functions(a), functions(b));
        otherwise
            
            if isempty(reltol)
                same = isAlmostEqual(a, b);
            elseif reltol == 0
                same = isequalwithequalnans(a,b);
            else
                same = isAlmostEqual(a,b,reltol);
            end
            
            if ~same
                if isa(a, 'numeric') && isa(b, 'numeric')
                    error('assert:assertEquals', ...
                        'Expected %s, got %s', mat2str(a), mat2str(b));
                elseif isa(a, 'char') && isa(b, 'char')
                    error('assert:assertEquals', 'Expected "%s", got "%s"', a, b);
                else
                    error('assert:assertEquals', ...
                          'expected equal arguments, got different');
                end
            end
    end
end

    function errorHandler(err, varargin)
        err.message = sprintf('%s\n At index %d of traversal', ...
            err.message, err.index);
        rethrow(err);
    end
end
