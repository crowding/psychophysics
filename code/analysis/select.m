function what = select(array, fn)
    %function selected = select(array, fn)
    if iscell(array)
        what = array(boolean(cellfun(fn, array)));
    else
        what = array(boolean(arrayfun(fn, array)));
    end
end