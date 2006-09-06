function this = Trigger
    %the Trigger interface.
    %
    %see also SpaceEvents.
    this = public(@check, @draw);
    
    function check(x, y, t, next)
        %Implementors check if the arguments meet some criteria, and
        %perform some action if true.
        %
        %x:    the x-coordinate of the gaze (may be NaN)
        %y:    the y-coordinate of the gaze (may be NaN)
        %t:    the time the gaze sample was taken
        %next: the next scheduled screen refresh. 
    end

    function draw(window, toPixels)
        %For diagnostic purposes, triggers may implement a drawing function
        %which e.g. draws their boundaries on the screen.
        %
        %See also TriggerDrawer.
    end
end