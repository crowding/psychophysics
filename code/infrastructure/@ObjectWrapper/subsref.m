function varargout = subsref(this, s)
    [varargout{1:nargout}] = subsref(this.wrapped, s);
end