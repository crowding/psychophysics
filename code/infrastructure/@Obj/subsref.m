function varargout = subsref(this, subs)
    [varargout{1:nargout}] = subsrefstep(this.wrapped, subs);
end

function varargout = subsrefstep(wrapped, subs)
    %since my objects pretend to be a struct when they're not, we
    %have to drill down a step at a time.
    if strcmp(subs(1).type, '.') && isobject(wrapped) && any(strcmp(wrapped.property__(), subs(1).subs))
        if numel(subs) <= 1
            [varargout{1:nargout}] = wrapped.property__(subs(1).subs);
        else
            [varargout{1:nargout}] = subsrefstep(wrapped.property__(subs(1).subs), subs(2:end));
        end
    else
        if numel(subs) <= 1
            [varargout{1:nargout}] = subsref(wrapped, subs(1));
        else
            [varargout{1:nargout}] = subsrefstep(subsref(wrapped, subs(1)), subs(2:end));
        end
    end
end