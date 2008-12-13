function varargout = subsref(this, subs)
    %try a non-recursive algorithm.
    whatsleft = this.wrapped; %the head of the data we have drilled down to so far

    for step = 1:numel(subs)-1
        property = subs(step).subs;
        if strcmp(subs(step).type, '.') && isobject(whatsleft) && ~isfield(whatsleft, property)
            try
                try
                    whatsleft = whatsleft.(getterName(property))();
                catch
                    whatsleft = whatsleft.property__(property);
                end
            catch
                %faster to ask forgiveness than permission...
                if ~any(strcmp(whatsleft.property__(), property))
                    error('Obj:noSuchProperty', 'No such property %s', property);
                else
                    rethrow(lasterror);
                end
            end
        else
            whatsleft = unwrap(subsref(whatsleft, subs(step)));
        end
    end
    
    %last one, varargout it.
    property = subs(end).subs;
    if strcmp(subs(end).type, '.') && isobject(whatsleft) && ~isfield(whatsleft, property)
        try
            try
                [varargout{1:nargout}] = whatsleft.(getterName(property))();
            catch
                [varargout{1:nargout}] = whatsleft.property__(property);
            end
        catch
            %faster to ask forgiveness than permission...
            if ~any(strcmp(wrapped.property__(), property))
                error('Obj:noSuchProperty', 'No such property %s', property);
            else
                rethrow(lasterror);
            end
        end
    else
        [varargout{1:nargout}] = subsref(whatsleft, subs(end));
        [varargout{1:nargout}] = unwrap(varargout{1:nargout});
    end
end