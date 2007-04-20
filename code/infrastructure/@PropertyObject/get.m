% Gets properties of an object by name.
function val = get(this, propname);

a = accessors(this,propname);
val = a.getter(this);
