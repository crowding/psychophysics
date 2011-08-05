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
base = EyeCalibrationTrial('useOldTarget', 1);
endMessage = [];

seed = randseed(); %keep our own rand seed.

persistent init__;
this = autoobject(varargin{:});

    function [params, result] = run(params)
        %initialize data...
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
                while (base.getTargetX() == base.getOldTargetX() && base.getTargetY() == base.getOldTargetY());
                    base.setTargetX(targetX(ceil(rand*numel(targetX))));
                    base.setTargetY(targetY(ceil(rand*numel(targetY))));
                end
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
                if numel(results) >= 6
                    %try calibrating and see how good we are...
                    
                    %this solution works easiest in affine coordinates
                    r = results(max(1,end-maxUsed):end);
                    i = interface(struct('target', {}, 'endpoint', {}), r);
                    t = cat(1, i.target);
                    endpoints = cat(1, i.endpoint);
                    %undo the existing calibration...
                    raw = result.orig_slope\(endpoints' - result.orig_offset(:, ones(1, numel(i))));

                    atarg = t';
                    %atarg(3,:) = 1;
                    araw = raw; araw(3,:) = 1;

                    %amat * araw = atarg (in least squares sense)
                    %amat = atarg / araw;
                    %calib = amat * araw;
                    %stderr = sqrt(sum(sum((calib(1:2,:) - t').^2)) / (numel(results)) / sqrt(numel(results) - 1));
    
                    %now in robust fit!
                    [amat, stderr] = irls(atarg, araw, @tukey_weight, 100);

                    if isfield(params, 'uihandles') && ~isempty(params.uihandles)
                        makeCurrentAxes(params.uihandles.experiment_axes);
                        fitplot(atarg, araw, amat);
                        title(params.uihandles.experiment_axes, sprintf('max fit stderr = %g', stderr));
                    end
                    
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

    function [T err] = irls(targets, raw_endpoints, weightFn, iter)
        %What this algorithm does is to produce a fit by iteratively rewighting
        %each datapoint according to a function of its residual. It then offers
        %up a measure of the maximum standard error of all fitted points.

        weights = ones(1, size(targets, 2));
        for i = 1:iter
            wtargets = repmat(weights, size(targets, 1), 1) .* targets;
            wendpoints = repmat(weights, size(raw_endpoints, 1), 1) .* raw_endpoints;
            T = wtargets / wendpoints;
            residuals = T*raw_endpoints - targets;

            %Estimate scale. I do not understand completely how to extend hte
            %discussions of robust regression, which usually take a univariate
            %response variable, into a multivariate case, and it appears you can
            %choose the scale estimator -- discussion in chapter 7 of Huber --
            %so I am taking the simplest reccomendation for now which is the
            %median absolute deviation (MAD) of the absolute residuals...
            %however any kind of median seems sketchy when you're applying it
            %to a multivariate residual.
            %to go to the next part of the loop, calculate the weights based on
            %the current estimate of median and scale:
            if i < iter
                scale = 1.4826 * median(abs(sqrt(sum(residuals.^2,1)) - median(sqrt(sum(residuals.^2, 1)))));
                weights = weightFn(residuals./scale);
            end
        end

        %Calculate the errors the fitted datapoints. I do this by first using a
        %weighted jackknife technique to get varying parameter estimates and then
        %applying the varying parameter estimates to the original data.

        %Note, not trying to recalculate the weights when leaving out each
        %sample in the jackknife is a bit of a fudge.

        Tjack = zeros([size(T) size(targets, 2)]);
        jackfits = zeros([size(targets) size(targets, 2)]);
        for i = 1:size(targets, 2)
            indices = [1:i-1, i+1:size(targets,2)];
            Tjack(:,:,i) = wtargets(:,indices) / wendpoints(:,indices);
            jackfits(:,:,i) = Tjack(:,:,i) * raw_endpoints;
        end

        %Now we have a variance for each endpoint. NOTE we need to multiply by
        %a factor of (n-1)^2 to get the variance, as the jackknife fits
        %each vary one out of N points.
        pointcov = zeros(2,2,size(jackfits,2));
        pointerr = zeros(size(jackfits,2),1);
        for i = 1:size(jackfits, 2)
            pointcov(:,:,i) = cov(squeeze(jackfits(:,i,:))') * (size(jackfits,2)-1).^2;
            pointerr(i) = sqrt(trace(pointcov(:,:,i))/(size(jackfits,2)-1));
        end

        err = max(pointerr);
    end

    function fitplot(targets, raw_endpoints, T)
        %plot the original target locations connected to the endpoints
        %according to the transform
        transformed = T * raw_endpoints;
        plot...
            ( targets(1,:), targets(2,:), 'ko'...
            , [targets(1,:);transformed(1,:)], [targets(2,:);transformed(2,:)], 'r-'...
            , transformed(1,:), transformed(2,:), 'r.'...
            );    
    end


    function weights = tukey_weight(residuals)
        %weighting function based on Tukey's influence function
        c = 3.44; % chosen for 85% efficiency, per Maronna et al. 2006
        %The weighting function is applied to the absolute residuals.
        t = sqrt(sum((residuals).^2, 1));
        weights = (1 - (t./c).^2).^2;
        weights(t > c) = 0;
    end
end