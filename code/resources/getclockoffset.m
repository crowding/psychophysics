function [clockoffset, measured] = getclockoffset(details)

if details.dummy
    getTime = @getDummyTime;
else
    getTime = @getEyelinkTime;
end

% There is an offset between the mac and eyelink clocks.
% Additionally, the eyelink clock only returns an integer number of
% milliseconds. If t is the computer's clock, then the eyelink's clock s(t)
% is a stairstep function:
%
% s(t) = floor(1000*t + ofs)
%
% We take many samples and fit the best value of ofs. Noise and latency
% are assumed to be independent so they are ignored (I want a precise
% repeatable measurement, and don't care about its actual value so long as
% it can be compared across a number of trials.)
%
% Begin by taking a bunch of samples of the eyelink clock.

% Polling for the eyelink time does not appear to work when we are at
% a high priority--timeout errors are likely. So set a lower priority.

[time, pre_request, post_request] = ...
    require(highPriority(details, 'priority', 0), @collectdata);
    function [time, before, after] = collectdata
        [time, before, after] = ...
            arrayfun(@(i)getTime(0.05,10), 1:250);
    end

% The distribution of intervals (post_request - pre_request)
% is a J-curve -- I trust the short intervals. Select the best 50%
% of trials (where the request happened quickly):
crit = median(post_request - pre_request);
good = (post_request - pre_request) < crit;
time = time(good);
post_request = post_request(good);
pre_request = pre_request(good);


%%now see how closely we recreate the staircase. Here's a naive estimate
%%assuming uniorm sampling, which we will use to bootstrap a least
%%squares estimate.
%
est1 = mean(time - 1000*pre_request) + 0.5;

%%this is another estimator, but is more noisy:
%
%est2 = mean(time - floor(1000*pre_request));

%least squares fit method is more accurate. the staircase
%function is an ad hoc spline curve with a sharpness parameter.
est3 = fminsearch(...
    @(est) sum(staircase(1000*pre_request + est(1), est(2)) - time).^2,...
    [est1, 10]);

%{
%visual diagnostics

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
plot(abscissa, staircase(1000.*t + est3(1), est3(2)) - floor(1000*t), 'b-');
drawnow;
hold off;
%}

%output the clock offset and the time we measured it at
clockoffset = est3(1);
measured = mean(pre_request);

%----- helper functions -----
    function [time, before_request, after_request] = ...
            getEyelinkTime(softtimeout, hardtimeout)
        %requests the time from the eyelink, and the time before and after
        %the request was made. after 'softtimeout' has passed, the eyelink
        %is prodded again. After 'hardtimeout' has passed, an error is
        %thrown. Unreliable stuff, this...

        before_request = GetSecs();
        status = Eyelink('RequestTime'); %do it twice for luck!!!
        after_request = GetSecs();
        
        if status ~= 0
            error('doClockSync:badStatus', ...
                'status %d from requesttime', status);
        end
        
        start = before_requst;
        time = 0;
        while(time == 0)
            s = GetSecs();
            
            if (s - start) > hardtimeout
                
                error('getclockoffset:timeout', ...
                      'timeout waiting for clock information from eyelink');
                  
            elseif (s - timeout) > softtimeout
                
                warning('doClockSync:eyelinkNotResponding', ...
                    'Eyelink not responding, prodding again (%s)', GetSecs);
                
                %request the time again...
                before_request = GetSecs();
                status = Eyelink('RequestTime');
                status = Eyelink('RequestTime'); %and do it twice for luck!!!
                after_request = GetSecs();
                %actually, for more than luck... it seems SR's eyelink library
                %helpfully screws things up sometimes when the connection
                %has been idle.

                timeout = s;
            end

            time = Eyelink('ReadTime');
        end
    end

    function [time, before, after] = getDummyTime(timeout, hardtimeout);
        offset = 19237.4829;
        %dummy version of the above
        before = GetSecs();
        time = floor(GetSecs() * 1000 + offset + rand() * 0.1);
        after = GetSecs();
    end
end
