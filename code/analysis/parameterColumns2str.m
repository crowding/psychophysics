function out = parameterColumns2str(c)
    out = cellfun(@s2s, c, 'UniformOutput', 0);

    function out = columnString(what)
        if iscell(what)
            %ummm sometimes the substruct are a struct...
            out = cellfun(@s2s, what, 'UniformOutput', 0);
            
            %ummm sometines it's a cell
            out = ['[' join(', ', out) ']'];
        else
            out = substruct2str(what);
        end
    end

    function out = s2s(what)
        if iscell(what)
            if all(cellfun(@isstruct,what))
                out = s2s(cell2mat(what));
            else
                out = cellfun(@s2s, what, 'UniformOutput', 0);
                out = ['[' join(', ', out) ']'];
            end
        else
            out = substruct2str(what);
        end
    end
            
end