function i = checkinit()

    checkpoint();

    i = @ini;
    function [release, params] = ini(params)
        checkpoint();
        release = @rel;
    end

    function rel()
        checkpoint();
    end
end