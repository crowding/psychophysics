function this = saveobj(this)

if isfield(this.wrapped, 'saveobj')
    this = this.wrapped.saveobj(this);
end

end