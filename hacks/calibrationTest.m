function eyeCalibrationTest()

%I have an automated eye calibration routine that operates as follows:
%
%1. Show a target at a random location the screen;
%2. Wait for the initiation of a saccade, defined using a velocity
%   threshold on the uncalibrated eye position and a narrow latency window 
%   (80-200 ms, say). If no saccade is
%   present, abort trial.
%3. When the saccade terminates (velocity passeses below threshold, waiting
%   for a bit for the saccade to settle, then establish a window around the
%   saccade endpoint.
%4. If the uncalibrated eye position does not leave the fixation window for
%   some time (~1 sec), I give a reward, and record the target position and
%   the elicited saccade endpoint. 
%5. Keep collecting endpoints until a good calibration is obtained, under
%   some criteria (more on this later)

% One thing that can go wrong here is that a false positive (an eye
% movement
%unrelated to the target, that still passes the latency/fixation duration
%tests. These are relatively rare esp. with a trained subject but 
%exert a lot of leverage on the least squares fit when they happen, and
%usually require a manual intervention and a restart of the trial block
%when they happen. I'd like to get a good calibration despite these outliers. 

%To start this discussion, here is a dummy transform. This is written as an
%affine transform in homogeneous coordinates (3x3); that is, if [X;Y;1] is
%the raw uncalibrated endpoint, the corresponing screen coordinate is [x,
%y, 1] = true_transform * [X;Y;1]. Homogeneous coordinates (i.e.
%introducing the third coordinate that is always equal to 1) are a trick to
%support both a slope and offset on one matrix. They also come in handy for
%reweighting in the irls argorithm, below.

true_transform = [
     15.2   3.2  12.3;
    -1.3   12.3  33;
     0      0    1;
    ];

%Here the upper left 2x2 gives the gain of the eyelink's raw measurement
%into screen coordinates. This is similar to the gain you can adjust in the
%eyelink configuration screen, but the off diagonal elements allow a skew
%or rotation (necessary if your hot mirror is mounted off-center!) The
%first couple of entries in the third column gives the offset.

%Now I will generate some fake data. This consists of a sequence of target
%presentations in degree coordinates with a sequence of obtained raw
%fixatin coordinates. 25 points with an average fixation error of 0.5
%degree:

[targets, raw_endpoints] = fake_data(true_transform, 25, 0, 0.5, 20);

%now one obvious way to recover the true transform from the fake data is to
%find the coeficients that best fit the data in the least squares sense.
%You can do that in matlab with just a right division:
T = targets / raw_endpoints;

%Here we make a plot to show how this fit performs.
figure(1);
subplot(2, 2, 1);
fitplot(targets, raw_endpoints, T)
title ('least squares');
xlim([-15 15]);
ylim([-15 15]);

%In this plot the dark circles are the target locations and the connected
%red dots show the saccade endpoints after the best transform has been applied.
%The calibration here looks pretty good.

subplot(2, 2, 2);
[T, err] = irls(targets, raw_endpoints, @tukey_weight, 100);
fitplot(targets, raw_endpoints, T);
title(sprintf('biweight, maxerr = %g', err));
xlim([-15 15]);
ylim([-15 15]);

%But what if we throw in a
%couple of outliers?

subplot(2,2,3);
[targets, raw_endpoints] = fake_data(true_transform, 25, 2, 0.5, 20);
T = targets / raw_endpoints;
fitplot(targets, raw_endpoints, T);
xlim([-15 15]);
ylim([-15 15]);
title('with outliers')
%That threw us off by a lot! Yikes!

%So we need a procedure that is more robust to errors in the data. We will
%use Iterative Reweighted Least Squares to seek a better fit under a
%different fit criterion 
%
%Here the concept of the "influence function" comes in useful. Roughly, the
%influence function for an estimator gives the degree to which a new sample
%at point X changes the estimate.

% For example, the influence function for the arithmetic mean is the
% function y=x -- a new sample will change the mean in proportion to the
% distance of the new sample from the previous mean.
%
% The influence function for the median, on the other hand, is the sign
% function times sqrt(pi/2) -- (under the assumption that we are estimating
% the mean of a normal dist. -- apparently this is slightly different from the
% empirical influence funxtion)
% but the point is that high smples influence the median equally)
%
% Note that the incluence function is defined relative to a specific value
% of the statistic being estimated (and sometimes for the distribution being
% modeled)

% How does this relate to least squares? Well, least squares minimizes the
% sum of (raw_endpoints * T - targets)^2....
%
% So for an M-estimator


%Now, the regular least squares

%First, let's
%write IRLS using actual square error as the minimizer function 
subplot(2,2,4);
T = irls(targets, raw_endpoints, @tukey_weight, 100);
fitplot(targets, raw_endpoints, T);
title('with outliers');
title(sprintf('With outliers, maxerr = %g', err));
xlim([-15 15]);
ylim([-15 15]);
%how'd that do? Better? Sometimes it 'collapses'!

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

function weights = tukey_weight(residuals)
    %weighting function based on Tukey's influence function
    c = 3.44; % chosen for 85% efficiency, per Maronna et al. 2006
    %The weighting function is applied to the absolute residuals.
    t = sqrt(sum((residuals).^2, 1));
    weights = (1 - (t./c).^2).^2;
    weights(t > c) = 0;
end


function [targets, endpoints] = fake_data(true_transform, nSamples, nOutliers, fixationSD, outlierSD)
    %we sample randomly around the grid.
    [sample_y, sample_x] = ndgrid(-10:5:10);
    i = Randi(numel(sample_y), [nSamples 1]);
    targets = [sample_x(i), sample_y(i)]';

    %the fixation accuracy
    fixationSD = 0.5;

    true_fixes = targets + fixationSD * randn(size(targets));

    %there are a few outliers
    outlier_i = RandSample([1:nSamples], [1 nOutliers]);
    true_fixes(:,outlier_i) = true_fixes(:,outlier_i) + outlierSD*randn(2,nOutliers);

    %affine coords:
    true_fixes(3,:) = 1;

    %undo the transform into raw coordinates...
    %true_transform*endpoints' = true_fixes;
    endpoints = (true_transform \ true_fixes);
end
