    function assertEquals(a, b)
        if (ndims(a) ~= ndims(b))
            error('assert:assertEquals', ...
                'Arguments have different numbers of dimensions (%s versus %s)', ...
                mat2str(ndims(a)), mat2str(ndims(b)));
        elseif (~all(size(a) == size(b)))
            error('assert:assertEquals', ...
                'Arguments are of unequal size (%s versus %s)', ...
                mat2str(size(a)), mat2str(size(b)));
        elseif iscell(a) && iscell(b)
            cellfun(@assertEquals, a, b, 'ErrorHandler', @errorHandler);
        elseif isstruct(a) && isstruct(b)
            error('Struct comparison not implemented.');
        elseif ~all(a == b)
            if isa(a, 'numeric') && isa(b, 'numeric')
                error('assert:assertionFailed', ...
                    'Expected %s, got %s', mat2str(a), mat2str(b));
            elseif isa(a, 'char') && isa(b, 'char')
                error('assert:assertionFailed', 'Expected "%s", got "%s"', a, b);
            else
                error('assert:assertEquals', ...
                    'expected equal arguments, got different types');
            end
        end
        
        function errorHandler(err, varargin)
            err.message = strvcat(err.message, sprintf('At index %d of traversal', err.index));
            disp(err.message);
            rethrow(err);
        end
    end
