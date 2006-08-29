function this = subsref(this, subs, val)
    if numel(subs) > 0
        this.setter(subsasgn(this.getter(), subs, val));
    else
        this.setter(val);
    end
end