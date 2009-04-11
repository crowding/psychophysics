function what = select(fn, array)
    %function selected = select(fn, array)
    if iscell(array)
        what = array(boolean(cellfun(fn, array)));
    else
        what = array(boolean(arrayfun(fn, array)));
    end
end