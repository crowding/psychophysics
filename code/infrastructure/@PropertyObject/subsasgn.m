%does this slow shit down? a lot? doe to recursive invocations during set()?
function this = subsasgn(this, S, val);
if ~isa(this, 'PropertyObject') 
    this = builtin('subsasgn', this, S, val);
    return
end
% function this = subsasgn(this, S, val);
%
% Implements subscripted assignment on objects with some resemblance to how
% it already works on structs.
if numel(this) == 0 && numel(S) == 1 && strcmp(S.type, '()');
	% Special case. When performing a statement of the form
	% undefined(index) = object, the expected behavior is for a new array
	% to be created. But MATLAB sucks and gives a new array of type double,
	% which you can't assign an object into. So we give a workaround.
	
	this = val([]); % assign the right type
    this(S.subs{:}) = val;
end
	
switch S(1).type
    case '()'
        if length(S) > 1
            this(S(1).subs{:}) = subsasgn(this(S(1).subs{:}), S(2:end), val);
        else
            this(S.subs{:}) = val;
        end
    case '.'
        if length(S) > 1
            this = set(this, S(1).subs, subsasgn(get(this, S(1).subs), S(2:end), val));
        else
            this = set(this, S.subs, val);
        end
    otherwise
        error('PropertyObject:subsref_type', 'Subscript method %s not supported for type %s.', S.type, class(this));
end
