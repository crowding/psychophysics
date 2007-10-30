function this = subsasgn(this, subs, what)
    %just pass the subsref on...
    this.wrapped = subsasgnstep(this.wrapped, subs, what);
    
    function wrapped = subsasgnstep(wrapped, subs, what)
        %since some things pretend to be a struct when they're not, we 
        %have to drill down a step at a time
        if strcmp(subs(1).type, '.') && isobject(wrapped)
            if any(strcmp(wrapped.property__(), subs(1).subs))
                if numel(subs) <= 1
                    wrapped.property__(subs(1).subs, what);
                else
                    %First pass: set everything in the chain. This could be
                    %more efficient as we only really need to set the property
                    %on the last reference object in the chain.
                    wrapped.property__...
                        ( subs(1).subs...
                        , subsasgnstep...
                        ( wrapped.property__(subs(1).subs)...
                        , subs(2:end)...
                        , what) ...
                        );
                end
            else
                error('Obj:noSuchProperty', 'No such property %s', subs(1).subs);
            end
        else
            if numel(subs) <= 1
                wrapped = subsasgn(wrapped, subs(1), what);
            else
                %again a drill down and assign, could be more efficient.
                wrapped = subsasgnstep...
                    ( subsref(wrapped, subs(1))...
                    , subs(2:end));
            end
        end
    end
end