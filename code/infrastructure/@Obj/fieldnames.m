function names = fieldnames(this)
    if builtin('isstruct', this.wrapped) && builtin('isfield', this.wrapped, 'property__')
        names = this.wrapped.property__();
    else
        names = builtin('fieldnames', this.wrapped);
    end
end