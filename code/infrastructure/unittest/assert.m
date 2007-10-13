function assert(value, varargin)

if ~value
    e.identifier = 'MATLAB:assert:failed';
    if nargin >= 2
        e.message = sprintf(varargin{:});
    else
        e.message = 'Assertion failed';
    end

    error(e);
end