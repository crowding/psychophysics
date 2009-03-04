function error = addcause(error, cause)
%function error = addcause(error, cause)
%
%It is often the case that in responding to an error or cleaning up
%resources, additional errors will be generated. In some languages (e.g.
%Java, Python) the original causing error is automatically included in the
%stack trace. But not so in MATLAB -- the original error is lost to
%the aether, unless you take special steps to capture it. Boo!
%
%This function combines two error structures as returned from LASTERROR.
%
%Example:
%try
%   do_something()
%catch
%   e = lasterror
%   try
%       do_cleanup();
%   catch
%       e = adderror(lasterror, e);
%   end
%
%See also REQUIRE, LASTERROR, STACKTRACE.

if isa(error, 'MException');
    error = mexception2errstruct(error);
end

if isa(cause, 'MException');
    cause = mexception2errstruct(cause);
end

if ~isfield(original.stack, 'cause')
    original.stack(1).cause = [];
end
if ~isfield(cause.stack, 'cause')
    cause.stack(1).cause = [];
end

%plug the exception in at the first place where the stack traces differ
where = 1;
for i = 0:min(length(original.stack), length(cause.stack)) - 1;
    if ~isequal(original.stack(end-i), cause.stack(end-i))
        cause.stack(end-i+1:end) = [];
        where = length(original.stack) - i;
        break;
    end
end

error.stack(where).cause = [error.stack(where).cause(:);cause];