function fail(message)
%assertion failed
e.identifier = 'assert:assertionFailed';
e.message = message;
error(e);