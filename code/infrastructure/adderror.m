function original = adderror(original, cause)

%attach the causing error to the stack trace. Elide the bits of stack
%trace that are identical.

if ~isfield(original.stack, 'additional')
    original.stack(1).additional = [];
end
if ~isfield(cause.stack, 'additional')
    cause.stack(1).additional = [];
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

original.stack(where).additional = [original.stack(where).additional(:);cause];
