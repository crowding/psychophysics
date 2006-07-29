    function assertEquals(a, b)
        if ~all(a == b)
            if isa(a, 'numeric') && isa(b, 'numeric')
                error('assert:assertionFailed', ...
                    'Expected %s, got %s', mat2str(a), mat2str(b));
            elseif isa(a, 'char') && isa(b, 'char')
                error('assert:assertionFailed', 'Expected "%s", got "%s"', a, b);
            else
                error('assert:assertEquals', ...
                    'expected equal arguments, got different');
            end
        end
    end
