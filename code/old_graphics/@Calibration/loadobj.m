function this = loadobj(what)

    if isa(what, 'Calibration')
        this = what;
    else
        names = fieldnames(what);
        
        this = arrayfun(@instantiate, what, 'UniformOutput', 0);
        this = reshape(cat(1,this{:}), size(what));
        %FACE fuckin' PALM that none of the array manipulations work on
        %objects in MATLAB.
        [this, signal] = Calibration(this);
    end

    function it = instantiate(s)
        s = struct2cell(s);
        args = {names{:}; s{:}};
        [it, signal] = Calibration(args{:});
    end

end