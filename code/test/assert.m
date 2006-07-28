function assert(value, message)

e.identifier = 'assert:assertionFailed';
if nargin >= 2
    e.message = message;
else
    e.message = 'Assertion failed';
end

error(e);