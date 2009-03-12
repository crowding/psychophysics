function what = select(array, fn)
    %function selected = select(array, fn)
    if iscell(fn)
        what = array(boolean(cellfun(fn, array, 'UniformOutput', 0)));
    else
        what = array(boolean(arrayfun(fn, array)));
    end
end