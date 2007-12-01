%Here is a simple wrapper to give subsref/subsasgn access for my objects.

function this = Obj(wrapped)

if isa(wrapped, 'Obj')
    this = wrapped;
else
    this = struct('wrapped', {wrapped});
    this = class(this, 'Obj');
end