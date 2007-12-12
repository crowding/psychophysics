function is = isfield(this, c)
    if builtin('isstruct', this.wrapped) && builtin('isfield', this.wrapped, 'property__')
        names = this.wrapped.property__();
    else
        names = builtin('fieldnames', this.wrapped);
    end
    
    names = names(:)';
    if ~isempty(names)
        names(2,end) = {[]};
    end
    s = struct(names{:});
    
    is = isfield(s, c);
end