function assertLastError(fragment)
%ASSERTLASTERROR(fragment)
%
%Asserts that the identifier last error received matches the identifier
%fragment (as in ERRORMATCH.)
err = lasterror;

%TODO: capture and propagate 'caused by' information?
%until then, just concatenate stack traces

if ~errormatch(fragment, err.identifier)
    newerr.identifier = 'assert:assertionFailed';
    newerr.message = sprintf('expected error "%s", got "%s"',...
        fragment, err.identifier);
    newerr.stack = [err.stack; dbstack];
    error(newerr);
end