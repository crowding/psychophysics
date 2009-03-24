function params = filterParams()
%eye filter parameters for charlie
%written as an m-file because then it winds up in the dependency graph.
    params = struct ...
        ( 'lowpassCutoff', 25 ... %Hz, for analog filter.
        , 'lowpassOrder', 4 ... %number of poles
        , 'velocityThreshold', 40 ... %degrees/sec, to mark beginning and end of saccades.
        , 'preSaccadeEndpointInterval', 0.030... %mark the velocity/endpoint this long before the start of the saccade.
        , 'preSaccadeVelocityInterval', [0.070 0.020] ... %average the vel;ocity over this interval following the end of the sacccade
        , 'postSaccadeEndpointInterval', 0.060... %mark the velocity/endpoint this long after the end of the saccade.
        , 'postSaccadeVelocityInterval', [0.035 0.085] ... %average the vel;ocity over this interval following the end of the sacccade
        , 'debounce', 0.030 ... %debounce for velocity threshold crossings
        , 'plotSaccadeMarking', 1 ... %plot the process of saccade marking
        , 'pausePlotting', 0 ... %pause for inspection
        );
