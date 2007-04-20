% check if there is a field or accessor for a given property name. 
function r = has_property(o, propname);

r = 0;

if ismethod(o, ['get_' propname])
	r = 1;
	return;
else
	s = struct(o);
	if isfield(s, propname)
		r = 1;
		return;
	end

	%walk up the inheritance heriarchy until a match is found.
	flds = fields(o);
	longflds = fields(o, '-full');
	for i = 1:length(flds)
		if strfind(longflds{i}, '% inherited object')
			parent = getfield( o, flds{i} );
			if has_property(parent, propname)
				r = 1;
				return;
			end
		end
	end
end
