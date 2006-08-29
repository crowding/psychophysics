function out = subsref(this, subs)
    try
        if numel(subs) > 0
            out = subsref(this.getter(), subs);
        else
            out = this.getter();
        end
    catch
        rethrow(lasterror);
    end
end