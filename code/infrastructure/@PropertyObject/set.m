
% o = set(o, 'propertyname', value)
% 
% Sets properties of an object.
%
% This tries to be generic so that any class inheriting this function has 
% reasonable "set" behavior on named properties.
function o = set(o, varargin);

args = varargin;

while(length(args) >= 2)
	propname = args{1};
	propvalue = args{2};
	args = args(3:end);

	o = setprop(o, propname, propvalue);
end
