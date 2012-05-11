function PowermateDemo()
%displays any movements of the knob, until its button is pressed and 
%released. 

knob = PowermateInput();

%the knob driver must be initialized before you use it, and must be closed
%after you're done using it. The most reliable way to do both is by using 
%the require() function. which tries as hard as possible to clean things up
%after loop() stops for any reason.
require(knob.init, knob.begin, @loop);

function loop(params)
    s = knob.input(struct());
    while 1
        if (s.knobRotation || s.knobDown || s.knobUp)
            disp(s);
        end
        if s.knobUp
            break
        end
        s = knob.input(s);
    end
end

end