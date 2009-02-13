function this = loadobj(what)

    if isa(what, 'Calibration')
        this = what;
    else
        names = fieldnames(what);
        
        this = num2cell(arrayfun(@instantiate, what, 'UniformOutput', 0));
    end

    function it = instantiate(s)
        s = struct2cell(s);
        args = {names{:}; s{:}};
        [it, signal] = Calibration(args{:});
    end

end