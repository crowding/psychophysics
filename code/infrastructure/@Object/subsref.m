function varargout = subsref(this, s)

switch s(1).type
    case '.'
        try
            [varargout{1:nargout}] = subsref(this.wrapped.(s(1).subs), s(2:end));
        catch
            rethrow(lasterror)
        end
    otherwise
        error('ObjectWrapper:subsref', 'other forms of subsref not implemented.');
end


%{
switch s(1).type
    case '.'
        name = s(1).subs;
        
        i_have_properties = isfield(this.wrapped, 'properties__');
        
        name_is_my_property = i_have_properties ...
            && any(strmatch(name, this.wrapped.properties__, 'exact'));
            
        if name_is_my_property
            if numel(s) > 1
                [varargout{1:nargout}] = ...
                    subsref(this.wrapped.(name)(), s(2:end));
            else
                [varargout{1:nargout}] = this.wrapped.(name)();
            end
        else
            if numel(s) > 1
                [varargout{1:nargout}] = ...
                    subsref(this.wrapped.(name), s(2:end));
            else
                
            end
        end
    otherwise
        error('ObjectWrapper:subsref', 'other forms of subsref not implemented.');
end

%}

end