function this = subsasgn(this, subs, what)
    %just pass the subsref on...
    this.wrapped = subsasgnstep(this.wrapped, subs, what);
end

    function [wrapped, assign] = subsasgnstep(wrapped, subs, what)
        %since some things pretend to be a struct when they're not, we 
        %have to drill down a step at a time.
        if strcmp(subs(1).type, '.') && isobject(wrapped)
            try
                if numel(subs) <= 1
                    try
                        %faster to do this nonsense because of slowness of loading structs :(
                        wrapped.(setterName(subs(1).subs))(what);
                    catch
                        wrapped.(property__(subs(1).subs, what));                        
                    end
                    %since we set on a reference object, there is no need
                    %to propagate the subsasgn out
                    assign = 0;
                else
                    
                    %we have a reference object, therefore need to
                    %drill down. How does this work?
                    
                    try
                        sub = wrapped.(getterName(subs(1).subs))();
                    catch
                        sub = wrapped.property__(subs(1).subs);
                    end
                    
                    [new, assign] = subsasgnstep ...
                        ( sub ...
                        , subs(2:end) ...
                        , what ...
                        );
                    if assign
                        try
                            wrapped.(setterName(subs(1).subs))(new);
                        catch
                            wrapped.property__( subs(1).subs, new );
                        end
                    end
                end
            catch
                %faster to ask forgiveness than permission...
                if ~any(strcmp(wrapped.property__(), subs(1).subs))
                    error('Obj:noSuchProperty', 'No such property %s', subs(1).subs);
                else
                    rethrow(lasterror);
                end
            end
        else
            if numel(subs) <= 1
                wrapped = subsasgn(wrapped, subs(1), what);
                assign = 1;
            else
                %again a drill down. could be more efficient: only one
                %subsasgn needs to be done for each chain of objects that's
                %not an OBJ...
                [new, assign] = subsasgnstep...
                        ( subsref(wrapped, subs(1))...
                        , subs(2:end) ...
                        , what ...
                        );
                if assign
                    wrapped = subsasgn( wrapped, subs(1), new );
                end
            end
        end
    end