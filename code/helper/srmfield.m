function str = srmfield(str, fields)
    %small/fast replacement for rmfield.
    c = struct2cell(str);
    f = fieldnames(str);
    nr = 0;
    for i = 1:numel(f)
        if any(streq(f{i-nr}, fields))
            c(i-nr,:) = [];
            f(i-nr) = [];
            nr = nr+1;
        end
    end
    str = cell2struct(c, f, 1);
end