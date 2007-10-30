%Here is a simple wrapper to give subsref/subsasgn access for my objects.

function this = Obj(wrapped)

this = struct('wrapped', {wrapped});
this = class(this, 'Obj');