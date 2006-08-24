function [clockoffset, measured] = getclockoffset(details)


if details.dummy
    getTime = @getDummyTime;
else
    getTime = @getEyelinkTime;
end

%Do many rounds of time checking and see what is the most accurate
%predictor.

%Note, polling for the eyelink time does not appear to work when we are at
%a high priority--timeout errors are likely. So set a lower priority 
%[time, pre_request, post_request] = collectdata();
[time, pre_request, post_request] = ...
    require(highPriority(details, 'priority', 0), @collectdata);
    function [time, before, after] = collectdata
        [time, before, after] = ...
            arrayfun(@(i)getTime(0.2), 1:500, 'ErrorHandler', @handler);
    end
    function [time, before, after] = handler(err, i)
        [time, before, after] = handlers(err, ...
            'doClockSync:timeout', @timeoutHandler);
        function [time, before, after] = timeoutHandler(err)
            message(details, 'Having dificulty reading eyelink clock (%d)', i);
            time = NaN;
            before = NaN;
            after = NaN;
        end
    end

% There is an offset between the mac and eyelink clocks.
% Additionally, the eyelink clock only returns an integer number of
% milliseconds. If t is the value of getSecs measured just before
% sampling the eyelink's clock, then the eyelink's clock s(t)
% equals:
%
% s(t) = floor(1000*t + ofs + noise)
%
% where noise is some latency and delay introduced between the
% computer time measurement and the request to measure the
% eyelink's time. ofs is the offset we desire to measure.
%
% We take many samples and fit the best value of ofs. Noise
% is assumed to be independent so it is ignored (I want a precise
% repeatable measurement, and don't care if it contains some small
% constant bias.)

%the distribution of intervals (post_request - pre_request)
%is a J-curve -- I trust the short intervals. Filter out the 50%
%of good trials (where the request happened quickly)
crit = median(post_request - pre_request);
good = (post_request - pre_request) < crit;
time = time(good);
post_request = post_request(good);
pre_request = pre_request(good);


%%now see how closely we recreate the staircase.
%%this is a naive estimator, and is not accurate (is biased due to
%%eyelink's rounding to milliseconds)
%
%est1 = mean(time - 1000*pre_request) + 0.5;

%%this one is more accurate, but assumes a uniform sampling so it
%%winds up being less precise. Will be used as a seed for the next
%%estimate.
%
est2 = mean(time - floor(1000*pre_request));

%least squares fit method is more precise/accurate. the staircase
%function is an ad hoc steplike spline function with a sharpness
%parameter.
est3 = fminsearch(...
    @(est) sum(staircase(1000*pre_request + est(1), est(2)) - time).^2,...
    [est2, 10]);


%{
%visual diagnostics: graph the fits

%visually inspect with the abscissa being mod(t, 1/1000) and the
%ordinate being s(t) - floor(1000*t) -- i.e. collapse the staircase down
%into one graph.

figure(1);
clf;
hold on;
abscissa = mod(pre_request, 0.001);
[abscissa, i] = sort(abscissa);
t = pre_request(i);
s = time(i);

plot(abscissa, s - floor(1000*t), 'k.');
plot(abscissa, floor(1000*t + est1) - floor(1000*t), 'r-');
plot(abscissa, floor(1000*t + est2) - floor(1000*t), 'g-');
plot(abscissa, staircase(1000.*t + est3(1), est3(2)) - floor(1000*t), 'g-');
drawnow;
hold off;
%}

%output the clock offset and the time we measured it at
clockoffset = est3(1);
measured = mean(pre_request);

%----- helper functions -----
    function [time, before_request, after_request] = getEyelinkTime(timeout)
        %requests the time from the eyelink, and the time before and after
        %the request was made. All responses are set to NaN if the eyelink
        %times out

        before_request = GetSecs();
        status = Eyelink('RequestTime');
        after_request = GetSecs();

        if status ~= 0
            error('doClockSync:badStatus', ...
                'status %d from requesttime', status);
        end

        time = 0;
        while(time == 0)
            before_check = GetSecs();
            time = Eyelink('ReadTime');
            after_check = GetSecs();
            
            if (after_check - before_check > 0.1)
                message(details, 'ReadTime took %0.2f seconds!');
                continue;
            end
            
            if (GetSecs() - after_request) > timeout
                %time = NaN;
                %post_request = NaN;
                %pre_request = NaN;
                %disp('timeout');
                %return
                message(details, 'timeout waiting for eyelink clock');
                error('doClockSync:timeout', ...
                      'timeout waiting for clock information from eyelink');
            end
        end
    end

    function [time, before_request, after_request] = getDummyTime(timeout);
        offset = 19237.4829;
        %dummy version of the above
        before_request = GetSecs();
        time = floor(GetSecs() * 1000 + offset + rand() * 0.1);
        after_request = GetSecs();
        if rand() > 0.999
            error('doClockSync:timeout', ...
                'random simulated timeout error');
        end
    end
end
