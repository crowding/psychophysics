function checker = keyIsDown(key)
    code = KbName(key);
    checker = @check;
    
    function [v, s] = check(s)
        v = any(s.keycodes == code);
    end
end