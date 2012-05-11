function [clockoffset, measured] = getclockoffset(details, nsamples)
%function [clockoffset, measured] = getclockoffset(details, nsamples)
%
%finds the clock offset between the eyelink and the host computer, in
%milliseconds.

%The Eyelink library is quite unhelpful and returns the time since library
%initialization, not the system time like GetSecs(). So if we want to use
%Eyelink('TimeOffset') which will shave 50 msec off our overhead during
%inter trial intervals we have to maintain another offset!

%welp, that didn't work, we have to do this the hard way.

if nargin < 1
    details = struct('dummy', 0, 'plot', 0);
end

if nargin < 2
    nsamples = 25; %good enough for 100 usec precision...
end

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

[time, pre_request, post_request] = deal(zeros(1,nsamples));
collect();
    function collect()
        for i = 1:nsamples
            [time(i), pre_request(i), post_request(i)] = getTime();
        end
        timeoffset = Eyelink('TimeOffset');
        lastTrackerTime_ = Eyelink('TrackerTime');
    end

% Sometimes it takes lerss than a millisecond to send to the Eyelink and 
% get the ping back eyelink, sometimes it's longer. The distribution of
% ping times is a J-curve -- I trust the short intervals. Select the best
% 50% of trials (where the response happened quickly):
crit = median(post_request - pre_request);
good = (post_request - pre_request) < crit;
time = time(good);
post_request = post_request(good);
pre_request = pre_request(good);

%%Here's a naive estimate assuming uniorm sampling, which we will use to as
%%the initial estimate for the staircase function.
%
est1 = mean(time - 1000*pre_request) + 0.5;

%The staircase function is an ad hoc spline curve with a sharpness parameter.
est3 = fminsearch(...
    @(est) sum(staircase(1000*pre_request + est(1), est(2)) - time).^2,...
    [est1, 10]);

if details.plot
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
end

%output the clock offset and the time we measured it at
clockoffset = est3(1);
measured = mean(pre_request);las

%----- helper functions -----
    function [time, before_request, after_request] = ...
            getEyelinkTime()
        %requests the time from the eyelink, expecting an answer soon.
        %Timeouts happen if you run this function under high priority!
        %The Eyelink('TrackerTime') doesn't have that problem but its
        %returned value wobbles about periodically by several milliseconds.

        before_request = GetSecs();
        status = Eyelink('RequestTime');
        after_request = GetSecs();

        if status ~= 0
            error('doClockSync:badStatus', ...
                'status %d from requesttime', status);
        end

        start = before_request;
        time = Eyelink('ReadTime');
        while(time == 0)
            s = GetSecs();
            if (s - start) > 0.1
                error('getclockoffset:timeout', ...
                      'timeout waiting for clock information from eyelink');
            end
            WaitSecs(0.0001);
            time = Eyelink('ReadTime');
        end
    end

    function [time, before, after] = getDummyTime();
        offset = 19237.4829;
        %dummy version of the above
        before = GetSecs();
        time = floor(GetSecs() * 1000 + offset + rand() * 0.1);
        after = GetSecs();
    end
end
