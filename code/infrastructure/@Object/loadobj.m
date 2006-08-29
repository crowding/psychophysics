function this = loadobj(this)
    if isfield(this.wrapped, 'loadobj')
        %if there's a loadobj method call it.
        this = this.wrapped.loadobj(this);
    end
        
    %FIXME:
    %
    %we can't
    %guarantee that a loadobj existed when the object was saved, but we
    %want to be able to 'upgrade' objects whose defining files later on
    %have a loadobj method.
    %
    %For future use, the Object constructor redords a handle to the
    %function that called it. This might be used to hunt down a loadobj__
    %method in the future.
end
