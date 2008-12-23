function varargout = subsref(this, subs)
    no = max(1,nargout);
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
                [varargout{1:no}] = whatsleft.(getterName(property))();
            catch
                [varargout{1:no}] = whatsleft.property__(property);
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
        %MATALB stupidity... bare calls to any function from the command
        %window invoke with 0 outputs. But if an output is returned the
        %command window can display it.
        if isa(whatsleft, 'function_handle')
            if nargout(whatsleft) == 0
                subsref(whatsleft, subs(end));
            else
            [varargout{1:no}] = whatsleft(subs(end).subs);
            end
        else
            [varargout{1:no}] = subsref(whatsleft, subs(end));
            [varargout{1:no}] = unwrap(varargout{1:no});
        end
    end
end