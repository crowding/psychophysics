function assert(value, message)

if ~value
    e.identifier = 'MATLAB:assert:failed';
    if nargin >= 2
        e.message = message;
    else
        e.message = 'Assertion failed';
    end

    error(e);
end