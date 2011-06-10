% o = setprop(o, 'propertyname', value)
% 
% Sets a property of an object.
%
% This tries to be generic so that any class inheriting this function has 
% reasonable "set" behavior on named properties.

function this = setprop(this, propname, propvalue)

a = accessors(this, propname);
this = a.setter(this, propvalue);
