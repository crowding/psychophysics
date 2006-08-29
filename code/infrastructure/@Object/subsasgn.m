function this = subsasgn(this, subs, value)
switch subs(1).type
    case '.'
        propname = subs(1).subs;
        if numel(subs) > 1
            oldval = get(this.wrapped.(propname));
            newval = subsasgn(oldval, subs(2:end), value);
            set(this.wrapped.(propname), newval);
        else
            set(this.wrapped.(propname), value);
        end

    otherwise
        error('ObjectWrapper:subsasgn:invalidType', ...
            '() or {} access not implemented for ObjectWrappers.');
end
end