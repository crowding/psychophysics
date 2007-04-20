function f = accessors(this, propname)
% function f = accessors(this, propname)
% return a structure with 'get' and 'set' fields; those fields containing 
% function references for how to get and set a property on an object.
% The values are cached when possible.

persistent cache;

try
	f = cache.(class(this)).(propname);
catch
	e = lasterror();
	disp([class(this) '.' propname]);

	if ~strcmp(e.identifier, 'MATLAB:nonStrucReference') && ...
		~strcmp(e.identifier, 'MATLAB:nonExistentField')

		rethrow(e);
	else
		f.getter = find_getter(this, propname);
		f.setter = find_setter(this, propname);
		%cache the functions for speed
		cache.(class(this)).(propname) = f;
	end
end

function getter = find_getter(this, propname)
	getmethod_name = ['get_', propname];
	if ismethod(this, getmethod_name)
		method = str2func(getmethod_name);
		getter = method;
	else
		s = struct(this);
		if isfield(s, propname) 
			getter = @(o) getfield(o, propname);
		else
			%walk up the inheritance heriarchy until a match is found.
			flds = fields(this);
			longflds = fields(this, '-full');
			for i = 1:length(flds)
				if strfind(longflds{i}, '% inherited object')
					parent = getfield( this, flds{i} );
					if has_property(parent, propname)
						parent_name = flds{i};
						parent_acc = accessors(parent, propname);
						getter = @(o) parent_acc.getter( getfield(o, parent_name) );
						return;
					end
				end
			end
			error('No such property %s', propname);
		end
	end

function setter = find_setter(this, propname)
	s = struct(this);
	%if you wish, code a method 'check_<propertyname>' to verify the 
	%value.
	checker_name = ['check_', propname];
	if ismethod(this, checker_name)
		checker = str2func(checker_name);
	else
		checker = @(o, value) 1;
	end

	if isfield(s, propname)

		% Ugly--this depends on copying "setfield.m" into each 
		% class.
		setter = @(o, value) setfield(o, propname, value);
		setter = @(o, value) ...
			prototype_setter(checker(o, value), propname, setter, o, value);
	else
		%walk up the inheritance heriarchy until a match is found. Ugh.
		flds = fields(this);
		longflds = fields(this, '-full');
		for i = 1:length(flds)
			if strfind(longflds{i}, '% inherited object')
				parent_name = flds{i};
				parent = getfield( this, parent_name );
				if has_property(parent, propname)
					parent_acc = accessors(parent, propname);
					setter = @(o, value) ...
						setfield(o, parent_name, ...
						   parent_acc.setter(getfield(o, parent_name), value));
					setter = @(o, value) ...
						prototype_setter(checker(o, value), propname, setter, o, value);
					return;
				end
			end
		end
		error('No such property %s', propname);
	end
	
function o = prototype_setter(pass, pn, setter, o, value)
	if pass
		o = setter(o, value);
	else
		error('Set:bad_value', 'bad value for %s', pn);
	end
