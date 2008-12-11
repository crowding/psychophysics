function this = subsasgn(this, subs, what)
    %just pass the subsref on...
    this.wrapped = subsasgnit(this.wrapped, subs, what);
end

function [wrapped, assign] = subsasgnit(wrapped, subs, what)
    %try a non-recursive algorithm.
    lowestrefobj = []; %the lowest reference object in the assignment chain
    property = [];
    belowit = []; %what data lies below in the tree
    subsleft = []; %what subscript lies below the lowest ref-obj

    whatsleft = wrapped; %the head of the data we have drilled down to so far

    for step = 1:numel(subs) -1 
        if strcmp(subs(step).type, '.') && isobject(wrapped)
            try
                lowestrefobj = whatsleft;
                property = subs(step).subs;
                try
                    belowit = wrapped.(getterName(property))();
                catch
                    belowit = wrapped.property__(property);
                end
                subsleft = subs(step+1:end);
                whatsleft = belowit;
            catch
                %faster to ask forgiveness than permission...
                if ~any(strcmp(wrapped.property__(), subs(step).subs))
                    error('Obj:noSuchProperty', 'No such property %s', subs(step).subs);
                else
                    rethrow(lasterror);
                end
            end
        else
            whatsleft = unwrap(subsref(whatsleft, subs(step)));
        end
    end

    %now we are up to all but the last assignment; what is it?

    if strcmp(subs(end).type, '.') && isobject(whatsleft)
        %the last assignment is ultimately a reference object assignment.
        %Whew. Just make the assignment!
        try
            try
                whatsleft.(setterName(subs(end).subs))(what);
            catch
                whatsleft.property__(subs(end).subs, what);
            end
        catch
            %faster to ask forgiveness than permission...
            if ~any(strcmp(whatsleft.property__(), subs(end).subs))
                error('Obj:noSuchProperty', 'No such property %s', subs(end).subs);
            else
                rethrow(lasterror);
            end
        end
    else
        if ~isempty(lowestrefobj)
            %we assign under the lowest reference object!
            newval = subsasgn(belowit, subsleft, what);
            %and update the value in teh reference object
            try
                try
                    lowestrefobj.(setterName(property))(newval);
                catch
                    lowestrefobj.property__(property, newval);
                end
            catch
                %faster to ask forgiveness than permission...
                if ~any(strcmp(lowestrefobj.property__(), property))
                    error('Obj:noSuchProperty', 'No such property %s', subs(1).subs);
                else
                    rethrow(lasterror);
                end
            end
        else
            %well hey. since no reference objects are involved, we complete
            %the assignment by normal means.
            wrapped = subsasgn(wrapped, subs, what);
        end
    end
end