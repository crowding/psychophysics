function DemoNight
%restart the demo in upon errors.
    while(1)
        try
            SteerableInteractive
            return
        catch
            stacktrace();
        end
    end
end