function x = substruct2str(subs)
    if iscell(subs)
        x = cellfun(@substruct2str, subs, 'UniformOutput', 0);
    else
        x = {};
        for i = numel(subs):-1:1
            if numel(subs(i).type) == 1
                x{i} = ['.' subs(i).subs];
            else
                x{i} = [subs(i).type(1) join(',', cellfun(@sub, subs(i).subs(:)', 'UniformOutput', 0)) subs(i).type(2)];
            end
        end
        
        x = [x{:}];
    end
end

function x = sub(s)
    switch class(s)
        case 'char'
            x = s;
        otherwise
            x = smallmat2str(s, 1);
    end
end

