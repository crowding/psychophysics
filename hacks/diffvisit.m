function diffvisit(old, new, assignfn, filterfn)
    %prints out the 'difference' of two objects via some statements that
    %will bring the old to the new.
    %FIXME this will not deal well with size/shape changes of cell/struct
    %arrays.
    
    if (nargin < 3)
        assignfn = @printeval;
    end
    
    if (nargin < 4)
        filterfn = @printfilter;
    end
    
    function doeval(subs, obj)
        fprintf('new%s = %s\n', substruct2str(subs), smallmat2str(obj));
    end

    function printfilter(subs, fn)
        fprintf('new%s = %s(%s)\n', substruct2str(subs), func2str(obj), substruct2str(obj));
    end

    %TODO: compare the filter functions...
    [oldraw, oldfilters] = toraw(old);
    
    filtidx = 1;
    oldfiltersunused = oldfilters;
    
    visit(new, @comparepiece, @comparefilters);
    
    function comparepiece(subs, obj)
        try
            if ~isequalwithequalnans(subsref(oldraw, subs), obj)
                 assignfn(subs, obj);
            end
        catch
            %if this errors out something bigger has changed -- perhaps the
            %type of an array or the size of a cell array, or an element
            %deleted.
            rethrow(lasterror);
        end
    end

    %WTF, in MATLAB there is no generic sort (by compare function) operation...
    function comparefilters(subs, newfilter)
        %nothing for now...
    end
end