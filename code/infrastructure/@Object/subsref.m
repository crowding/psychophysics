function varargout = subsref(this, s)

switch s(1).type
    case '.'
        try
            [varargout{1:nargout}] = subsref(this.wrapped.(s(1).subs), s(2:end));
        catch
            rethrow(lasterror)
        end
    otherwise
        error('Object:subsref', 'other forms of subsref not implemented.');
end

end
