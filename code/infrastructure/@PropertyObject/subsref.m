function R = subsref(this, S)
% function R = subsref(this, S)
% Implements subscripting so that object's properties may be read through 
% dot notation as with structs.

% S contains all references in a row. Recurse to find them.

switch S(1).type
	case '()'
		R = this(S(1).subs{:});
	case '.'
		R = get(this, S(1).subs);
	otherwise
		error('PropertyObject:subsref_type', 'Subscript method %s not supported for type %s.', S.type, class(this));
end

%recurse for consecutive references
if length(S) > 1
	R = subsref(R, S(2:end));
end
