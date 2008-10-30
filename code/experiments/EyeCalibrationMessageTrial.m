function this = EyeCalibrationMessageTrial(varargin)

%this is a 'trial' that does a full eye calibration, returning the slope
%and offset as its result. It contains an eye calibration trial and a
%message trial.

minN = 20;
maxN = 50;
maxUsed = 30;
maxStderr = 0.5; %target confidence interval on the regression...
interTrialInterval = 0.5;

minCalibrationInterval = 900; %recalibrate every 15 minutes or 100 trials...

targetX = [-10 -5 0 5 10];
targetY = [-10 -5 0 5 10];
    
beginMessage = [];
base = EyeCalibrationTrial();
endMessage = [];

seed = randseed(); %keep our own rand seed.

persistent init__;
this = autoobject(varargin{:});

    function [params, result] = run(params)
        %initialize data...
        figure = figure(2); clf;
        ax = axes();
        title('Eye calibration endpoints');

        result.orig_offset = params.input.eyes.getOffset();
        setOffset = params.input.eyes.setOffset;
        result.orig_slope = params.input.eyes.getSlope();
        setSlope = params.input.eyes.setSlope;
        
        if ~isempty(beginMessage)
            [params, result.beginMessageResult] = beginMessage.run(params);
            if isfield(result.beginMessageResult, 'abort') && (result.beginMessageResult.abort)
                result.success = 0;
                result.abort = 1;
                return;
            end
        end
        
        if isempty(params.input.eyes.getCalibrationDate()) ...
                || (datenum(clock()) - datenum(params.input.eyes.getCalibrationDate()))/datenum(0, 0, 0, 0, 0, 1) > minCalibrationInterval ...
                || ~isequal(params.input.eyes.getCalibrationSubject(),params.subject)
            %now we should recalibrate...
            %data points
            results = [];

            while true
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
                    if isempty(results)
                        results = res;
                    else
                        results(end+1) = res; %#ok
                    end
                end
                
                %manage the ITI
                if isfield(res, 'endTime') && isfield(base, 'setStartTime')
                    base.setStartTime(res.endTime + interTrialInterval);
                else
                    disp('ignoring inter trial interval');
                end

                if isfield(res, 'abort') && (res.abort)
                    result.success = 0;
                    result.abort = 1;
                    return;
                end

                %update the next trial...
                if numel(results) >= 5
                    %try calibrating and see how good we are...
                    %this solution works easiest in affine coordinates
                    r = results(max(1,end-maxUsed):end);
                    i = interface(struct('target', {}, 'endpoint', {}), r);
                    t = cat(1, i.target);
                    endpoints = cat(1, i.endpoint);
                    %undo the existing calibration...
                    raw = result.orig_slope\(endpoints' - result.orig_offset(:, ones(1, numel(i))));

                    atarg = t';
                    atarg(3,:) = 1;
                    araw = raw; araw(3,:) = 1;

                    %amat * araw = atarg (in least squares sense)
                    amat = atarg / araw;
                    calib = amat * araw;
    
                    makeCurrentAxes(ax);
                    plot(ax, calib(1,:), calib(2,:), 'b+');
                    hold(ax, 'on');
                    line([t(:,1)';calib(1,:)], [t(:,2)';calib(2,:)], 'Color', 'b');
                    hold(ax, 'off');
                    %set the offset and slope...

                    %what is the standard error? As a measure of how accurately we
                    %think we have calibrated, take the asolute error minus the
                    %veridical target position...

                    stderr = sqrt(sum(sum((calib(1:2,:) - t').^2)) / (numel(results)) / sqrt(numel(results) - 1));

                    title(ax, sprintf('stderr = %g', stderr));
                    
                    if ( (stderr < maxStderr) && ( numel(results) >= minN) ) || numel(results) >= maxN
                        %we're done. apply and record the calibration.
                        result.stderr = stderr;
                        result.results = results;
                        result.slope = amat([1 2], [1 2]);
                        setSlope(result.slope);
                        result.offset = amat([1 2], 3);
                        setOffset(result.offset);
                        printf('stderr = %g\n', stderr);
                        params.input.eyes.setCalibrationDate(clock);
                        params.input.eyes.setCalibrationSubject(params.subject);
                        break;
                    end
                elseif numel(results) >= 2
%{                  
                    r = results(max(1,end-maxUsed):end);
                    i = interface(struct('target', {}, 'endpoint', {}), r);
                    t = cat(1, i.target);
                    endpoints = cat(1, i.endpoint);
                    
                    plot(ax, endpoints(1,:), endpoints(2,:), 'b+');
                    hold(ax, 'on');
                    line(ax, [t(:,1)';endpoints(1,:)], [t(:,2)';endpoints(2,:)], 'Color', 'b');
                    hold(ax, 'off');
                    %}
                end
            end
        end

        %show the ending message trial, if applicable.
        if ~isempty(endMessage)
            [params, result.endMessageResult] = message.run(params);
            if isfield(result.endMessage, 'abort') && (result.endMessageResult.abort)
                result.success = 0;
                result.abort = 1;
                return;
            end
        end
        
        result.success = 1;
        result.abort = 0;
    end

end