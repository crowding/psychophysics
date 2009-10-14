function checker = keyIsDown(varargin)
    %function checker = keyIsDown(key)
    %condition check for a combination of keys. The arguments can be the
    %names of keys, or lists of names of keys. The condition passes if the
    %any of the key combinations pass.
    codes = cellfun(@(x)sort(KbName(x)), varargin, 'UniformOutput', 0);
    
    checker = @check;
    
    function [v, s] = check(s)
        v = 0;
        for i = codes
            if isequal(i{1}(:), s.keycodes(:))
                 v = 1;
                 return
            end
        end
    end
end