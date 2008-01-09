function this = EyeCalibrationTrial(varargin)
    %attempt an automatic eye calibration rom the given data.

    velocityThreshold = 20;
    
    %any saccades detected within these parameters will 
    minLatency = 0.1;
    maxLatency = 0.4;

    function params = run(params)
        
        spot = FilledDisk();
        trigger = Trigger
        m = mainLoop('triggers', {trigger});
        
        range = calibration.rect(1, 2)
        
        %since this designs a filter it's probably best to do it here
        triggerGreater = eyeVelocityAtLeast(velocityThreshold, params.eyeSampleRate, 
    end
    
end