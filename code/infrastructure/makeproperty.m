function propfn = makeproperty(propnames, propget, propset)
    %make property names into a struct
    propnames = apply(@struct, cat(1, propnames(:)', repmat({{}}, 1, numel(propnames))) );
    
    propfn = @property__;
    
    function value = property__(propname, value)
        if nargin == 0
            value = fieldnames(propnames);
            %value = propnames;
        elseif isfield(propnames, propname)
        %elseif strmatch(propname, propnames, 'exact')
            if nargin == 1
                value = propget(propname);
            elseif nargin >=2
                propset(propname, value);
            end
        else
            error('property:noSuchProperty', 'No such property ''%s''.', propname);
        end
    end
end