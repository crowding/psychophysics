function array = assign(array, subs, fn)
    if iscell(array)
        for i = 1:numel(array)
            array{i} = subsasgn(array{i}, subs, fn(array{i}));
        end
    else
        for i = 1:numel(array)
            array(i) = subsasgn(array(i), subs, fn(array(i)));
        end
    end
end