function this = MouseEvents(calibration_)
this = inherit(SpaceEvents(calibration_), public(@sample));

    function [x, y, t] = sample()
        %use the mouse coordinates instead
        %
        %NB: mouse coordinates on dual head systems are not the
        %same as window coordinated when the
        %display is not the leftmost (Psychtoolbox issue)
        %
        %Complaint:
        %If Psychtoolbox interfaced with HID devices properly
        %(like, for isntance, pygame does) we would have an
        %interface to an event queue that would keep track of (and
        %timestamp!!!) all of our data for us without having to
        %loop (and possibly miss events between loops).
        %
        %Complaint:
        %meanwhile, we could avoid polling eyelink if its own event
        %code worked on OSX.
        [x, y] = GetMouse();
        t = GetSecs();
    end
end