function this = EyeCalibrationMessageTrial(varargin)

%this is a 'trial' that does a full eye calibration, returning the slope
%and offset as its result. It contains an eye calibration trial and a
%message trial.

min_n = 20;
max_n = 50;
target_stderr = 0.5; %target confidence interval on the regression...
interTrialInterval = 0.5;

minCalibrationInterval = 900; %recalibrate every 15 minutes or 100 trials...

targetX = [-10 -5 0 5 10];
targetY = [-10 -5 0 5 10];
    
beginMessage = messageTrial();
base = EyeCalibrationTrial();
endMessage = MessageTrial();

seed = randseed(); %keep our own rand seed.

this = autoobject(varargin{:});

    function [params, result] = run(params)
        %initialize data...
        targetX = [];
        targetY = [];
        result.orig_offset = e.params.input.eyes.getOffset();
        setOffset = e.params.input.eyes.setOffset;
        result.orig_slope = e.params.input.eyes.getSlope();
        setSlope = e.params.input.eyes.setSlope;
        
        if ~isempty(beginMessage)
            [params, result.beginMessageResult] = beginMessage.run(params);
        end

        if isfield(result.beginMessage, 'abort') && (result.beginMessageResult.abort)
            result.success = 0;
            result.abort = 1;
            return;
        end
        
        if ~isempty(params.input.eyes.getCalibrationDate()) ...
                || datenum(clock()) - datenum(params.input.eyes.getCalibrationDate()) > minCalibrationInterval
            %now we should recalibrate...
            %data points
            results = struct();

            conf = Inf;

            while (size(endpoints, 1) < min_n) && (size(endpoints, 2) < max_n) && (conf > target_stderr)
                %collect another data point

                %pick an X and a Y
                rand('twister', seed);
                base.setTargetX(targetX(ceil(rand*numel(targetX))));
                base.setTargetY(targetY(ceil(rand*numel(targetY))));
                seed = rand('twister');

                %collect an eye movement...
                [params, res] = base.run(params);
                %update the data...
                if (res.success)
                    results(end+1) = res; %#ok
                end
                
                %manage the ITI
                if isfield(res, 'endTime') && isfield(base, 'startTime')
                    base.startTime = result.endTime + interTrialInterval;
                else
                    disp('ignoring inter trial interval');
                end

                if isfield(res, 'abort') && (res.abort)
                    result.success = 0;
                    result.abort = 1;
                    return;
                end

                %update the next trial...
                if size(endpoints, 1) > 5
                    %try calibrating and see how good we are...
                    %this solution works easiest in affine coordinates
                    atarg = t';
                    atarg(3,:) = 1;
                    araw = raw; araw(3,:) = 1;

                    %amat * araw = atarg (in least squares sense)
                    amat = atarg / araw;
                    calib = amat * araw;

                    %set the offset and slope...

                    %what is the standard error? As a measure of how accurately we
                    %think we have calibrated, take the asolute error minus the
                    %veridical target position...

                    stderr = sqrt(sum(sum((calib - t).^2)) / (numel(endpoints, 1) - 1))

                    if ( (stderr < target_stderr) && ( numel(results) >= min_n) ) || numel(results) >= max_n
                        %we're done. apply and record the calibration.
                        result.stderr = stderr;
                        result.results = results;
                        result.slope = amat([1 2], [1 2]);
                        setSlope(result.slope);
                        result.offset = amat([1 2], 3);
                        setOffset(result.offset);
                        printf('stderr = %g\n', stderr);
                        break;
                    end
                end
            end
        end

        %show the ending message trial, if applicable.
        if ~isempty(endMessage)
            [params, result.endMessageResult] = message.run(params);
        end
        
        if isfield(result.endMessage, 'abort') && (result.endMessageResult.abort)
            result.success = 0;
            result.abort = 1;
            return;
        end
        
        result.success = 1;
        result.abort = 0;
    end

end