function data = markSaccades(infile, outfile)
    %Filter and mark saccades for each calibrated trial.

    %default settings
    params = struct ...
        ( 'lowpassCutoff', 25 ... %Hz, for analog filter.
        , 'lowpassOrder', 4 ... %number of poles
        , 'velocityThreshold', 40 ... %degrees/sec, to mark beginning and end of saccades.
        , 'preSaccadeEndpointInterval', 0.030... %mark the velocity this long before the start of the saccade.
        , 'postSaccadeEndpointInterval', 0.060... %mark the velocity this long after the end of the saccade.
        , 'debounce', 0.020 ... %how long to debounce the threshold crossings
        , 'plotSaccadeMarking', 1 ... %plot the process of saccade marking
        , 'pausePlotting', 0 ... %pause for inspection
        );
    if exist('filterParams', 'file') == 2
        params = namedargs(params,filterParams());
    end
    
    persistent fig;
    
    if params.plotSaccadeMarking
        %find the figure window
        if isempty(fig) || ~any(get(0, 'children') == fig)
            fig = figure();
        end
        %activate it for plotting without raising
        set(0, 'CurrentFigure', fig);
        clf;
    end
    
    persistent continueAutomatically;
    
    if isempty(continueAutomatically)
        continueAutomatically = 0;
    end
    
    if ischar(infile)
        data = {};
        load(infile, 'data');
        data = cellfun(@makeMarks, data, 'UniformOutput', 0);
        save(outfile, 'data');
    else
        data = infile;
        data = cellfun(@makeMarks, infile, 'UniformOutput', 0);
    end

    function experiment = makeMarks(experiment)
        %strip whatever's before the final beginning of the experiment
        %um, this isn't generic.
%        t = cellfun(@(t)max([NaN eventTimes('settleFixation', t)]), experiment.trials, 'UniformOutput', 0);
%        experiment.trials = cellfun(@(tim, tr) stripbefore(tim, tr), t, experiment.trials, 'UniformOutput', 0);

        experiment.trials = cellfun(@filtered, experiment.trials, 'UniformOutput', 0);
        experiment.trials = cellfun(@differentiate, experiment.trials, 'UniformOutput', 0);
        experiment.trials = cellfun(@threshold, experiment.trials, 'UniformOutput', 0);
    end

    function times = eventTimes(eventname, trial)
        t = triggers(eventname, trial);
        times = [t.next];
    end

    function t = triggers(eventname, trial)
        t = trial.triggers(logical(cellfun('prodofsize',strfind({trial.triggers.name},eventname))));
    end

    function trial = stripbefore(time, trial)
        trial.triggers([trial.triggers.next] < time) = [];
        if ~isempty(trial.frame_skips)
            trial.frame_skips([trial.frame_skips.VBL] < time) = [];
        end
        
        eventT = arrayfun(@eventtime, trial.events);
        trial.events(eventT < time) = [];
        s = trial.samples.pct < time;
        trial.samples = structfun(@(x) x(~s), trial.samples, 'UniformOutput', 0);
    end

    function time = eventtime(e)
        if isfield(e, 'pctin') && ~isempty(e.pctin)
            time = e.pctin;
        else
            time = e.pct;
        end
    end

    function trial = filtered(trial)
        %filter the eye position traces with a zero phase butterworth
        %lowpass filter
        if isfield(trial, 'eyeData')
            %pull this back into the old format where we had trial.samples
            e = trial.eyeData;
            
            trial.samples.pcx = e(1,:);
            trial.samples.pcy = e(2,:);
            trial.samples.pct = e(3,:);
            
            trial = rmfield(trial, 'eyeData');
        end

        sampleInterval = median(diff(trial.samples.pct));
        cutoffSampleFreq = params.lowpassCutoff * sampleInterval * 2;
        
        %run the filter
        %[trial.samples.filteredx, delays] = filter(num, denom, trial.samples.pcx, zeros(size(trial.samples.pcy)));
        %[trial.samples.filteredy, delays] = filter(num, denom, trial.samples.pcy, zeros(size(trial.samples.pcy)));

        %compensate for average group delay in the passband
        %delay = sampleInterval * grpdelay(b, a, linspace(0, params.lowpassCutoff, 512), 1/sampleInterval));
        %[trial.samples.filteredt] = trial.samples.pct + (delay / sampleInterval)
        
        %[num, denom] = butter(params.lowpassOrder / 2, cutoffSampleFreq);
        %design the filter
        [num, denom] = butter(params.lowpassOrder / 2, cutoffSampleFreq);
        
        %now we need to interpolate over NaNs before filtering (as the IIR
        %filter carries NaNs through all the way...)
        pcx = trial.samples.pcx;
        pcy = trial.samples.pcy;
        pct = trial.samples.pct;
        
        ix = isnan(pcx);
        pcx(ix) = interp1(pct(~ix), pcx(~ix), pct(ix), 'cubic', NaN);

        ix = isnan(pcy);
        pcy(ix) = interp1(pct(~ix), pcy(~ix), pct(ix), 'cubic', NaN);
        
        %do not extrapolate beyond the bounds, 
        ix = isnan(pcx) | isnan(pcy);
        pcy(ix) = [];
        pcx(ix) = [];
        pct(ix) = [];
        
        trial.samples.filteredx = filtfilt(num, denom, pcx);
        trial.samples.filteredy = filtfilt(num, denom, pcy);
        trial.samples.filteredt = pct;
    end    

    function trial = differentiate(trial)
        %balanced difference
        sampleInterval = median(diff(trial.samples.pct));
        [trial.samples.vx] = conv(trial.samples.filteredx, [0.5 0 -0.5] / sampleInterval);
        [trial.samples.vy] = conv(trial.samples.filteredy, [0.5 0 -0.5] / sampleInterval);
        [trial.samples.vt] = trial.samples.filteredt;
        trial.samples.vx([1 2 end-1 end]) = [];
        trial.samples.vy([1 2 end-1 end]) = [];
        trial.samples.vt([1 end]) = [];
    end

    function trial = threshold(trial)
        %mark saccade starts and ends against a threshold of absolute eye velocity.
        sup = sqrt(trial.samples.vx.^2 + trial.samples.vy.^2) > params.velocityThreshold;
        
        startix = find(diff([1 sup]) > 0);
        endix = find(diff([sup 1]) < 0);
        
        %trim so that only complete saccades are included
        if ~isempty(startix) && ~isempty(endix)
            if endix(1) < startix(1)
                endix(1) = [];
            end
            if startix(end) > endix(end)
                startix(end) = [];
            end
        else
            [startix, endix] = deal([]);
        end
        
        %velocity threshold start and end times. Perhaps actually
        %interpolate and solve for the crossing times?
        saccades.startt = mean(trial.samples.vt([startix(:)-1 startix(:)]), 2);
        saccades.endt = mean(trial.samples.vt([endix(:) endix(:)+1]), 2);

        
        %debounce the threshold crossings (for underdamped eyes...)
        debounce = find(saccades.startt(2:end) - saccades.endt(1:end-1) < params.debounce);
        
        if params.plotSaccadeMarking
            clf;
            subplot(2, 1, 1); hold on;
            plot(trial.samples.vt, sqrt(trial.samples.vx.^2 + trial.samples.vy.^2));
            plot(saccades.startt(debounce+1), params.velocityThreshold(ones(size(debounce))), 'gx');
            plot(saccades.endt(debounce),   params.velocityThreshold(ones(size(debounce))), 'rx');
            subplot(2, 1, 2); hold on;
            plot(trial.samples.filteredt, trial.samples.filteredx, 'b-', trial.samples.filteredt, trial.samples.filteredy, 'r-');
        end
        
        %merge the adjacent sections
        for i = flipud(debounce(:))';
            saccades.endt(i) = saccades.endt(i+1);
            saccades.endt(i+1) = [];
            saccades.startt(i+1) = [];
        end
        
        %remove saccades where we don't have enough time for a start or
        %endpoint
        valid = (saccades.startt - trial.samples.vt(1)) > params.preSaccadeEndpointInterval ...
              & (trial.samples.vt(end) - saccades.endt) > params.postSaccadeEndpointInterval;
        saccades.startt(~valid) = [];
        saccades.endt(~valid) = [];
        
        saccades.startx = interp1(trial.samples.filteredt, trial.samples.filteredx, saccades.startt, 'cubic');
        saccades.starty = interp1(trial.samples.filteredt, trial.samples.filteredy, saccades.startt, 'cubic');
        saccades.startvx = interp1(trial.samples.vt, trial.samples.vx, saccades.startt, 'cubic');
        saccades.startvy = interp1(trial.samples.vt, trial.samples.vy, saccades.startt, 'cubic');

        saccades.endx = interp1(trial.samples.filteredt, trial.samples.filteredx, saccades.endt, 'cubic');
        saccades.endy = interp1(trial.samples.filteredt, trial.samples.filteredy, saccades.endt, 'cubic');
        saccades.endvx = interp1(trial.samples.vt, trial.samples.vx, saccades.startt, 'cubic');
        saccades.endvy = interp1(trial.samples.vt, trial.samples.vy, saccades.startt, 'cubic');

        saccades.pret = saccades.startt - params.preSaccadeEndpointInterval;
        saccades.prex = interp1(trial.samples.filteredt, trial.samples.filteredx, saccades.pret, 'cubic');
        saccades.prey = interp1(trial.samples.filteredt, trial.samples.filteredy, saccades.pret, 'cubic');
        saccades.prevx = interp1(trial.samples.vt, trial.samples.vx, saccades.pret, 'cubic');
        saccades.prevy = interp1(trial.samples.vt, trial.samples.vy, saccades.pret, 'cubic');
        
        saccades.postt = saccades.endt + params.postSaccadeEndpointInterval;
        saccades.postx = interp1(trial.samples.filteredt, trial.samples.filteredx, saccades.postt, 'cubic');
        saccades.posty = interp1(trial.samples.filteredt, trial.samples.filteredy, saccades.postt, 'cubic');
        saccades.postvx = interp1(trial.samples.vt, trial.samples.vx, saccades.postt, 'cubic');
        saccades.postvy = interp1(trial.samples.vt, trial.samples.vy, saccades.postt, 'cubic');
        
        [saccades.peakx, saccades.peaky, saccades.peakt, saccades.peakvx, saccades.peakvy] ...
            = arrayfun(@peak, saccades.startt, saccades.endt);

        function [x, y, t, vx, vy] = peak(startt, endt)
            interval = trial.samples.vt >= startt & trial.samples.vt <= endt;
            times = trial.samples.vt(interval);
            [tmp, i] = max(trial.samples.vx(interval).^2 + trial.samples.vt(interval).^2);
            
            t = times(i);
            x = interp1(trial.samples.filteredt, trial.samples.filteredx, t);
            y = interp1(trial.samples.filteredt, trial.samples.filteredy, t);
            vx = interp1(trial.samples.vt, trial.samples.vx, t);
            vy = interp1(trial.samples.vt, trial.samples.vy, t);
        end
        
        if params.plotSaccadeMarking
            subplot(2, 1, 1);
            plot(saccades.startt, params.velocityThreshold(ones(size(saccades.startt))), 'g.');
            plot(saccades.endt,   params.velocityThreshold(ones(size(saccades.endt))), 'r.');
            
            %twiddle the tick marks to show tiem form stimulus onset
            xt = get(gca, 'XTick');
            xl = get(gca, 'XLim');
            %plot actually the time from stimulus onset
            event = logical(cellfun('prodofsize', strfind({trial.triggers.name}, 'beginTrial')));
            if any(event)
                onset = trial.triggers(event).t;
            else
                onset = 0;
            end
            xt = xt - onset;
            interval = (xt(2) - xt(1));
            xt = ceil(xt(1)/interval)*interval:interval:floor(xt(end)/interval)*interval;
            set(gca, 'XTick', xt + onset);
            set(gca, 'XTickLabel', xt);
            
            subplot(2, 1, 2);
            
            plot(saccades.pret, saccades.prex, 'g.', saccades.postt, saccades.postx, 'r.');
            plot( [saccades.pret(:)-0.05, saccades.pret(:)+0.05]'...
                , (saccades.prex(:)*[1 1] + saccades.prevx(:) * [-0.05 0.05])'...
                , 'g-');
            plot( [saccades.postt(:)-0.05, saccades.postt(:)+0.05]'...
                , (saccades.postx(:)*[1 1] + saccades.postvx(:) * [-0.05 0.05])'...
                , 'r-');
                        
            plot(saccades.pret, saccades.prey, 'g.', saccades.postt, saccades.posty, 'r.');
            plot( [saccades.pret(:)-0.05, saccades.pret(:)+0.05]'...
                , (saccades.prey(:)*[1 1] + saccades.prevy(:) * [-0.05 0.05])'...
                , 'g-');
            plot( [saccades.postt(:)-0.05, saccades.postt(:)+0.05]'...
                , (saccades.posty(:)*[1 1] + saccades.postvy(:) * [-0.05 0.05])'...
                , 'r-');
            
            %plot(saccades.peakt, saccades.peakx, 'bo', saccades.peakt, saccades.peaky, 'bo', 'MarkerSize', 3);
            
            legend('H-position', 'V-position', 'saccade start', 'saccade end');
            
            set(gca, 'XTick', xt + onset);
            set(gca, 'XTickLabel', xt);
            
            drawnow;
            if params.pausePlotting && ~continueAutomatically
                r = input('continue with rest (2 to not ask again)?');
                if r
                    params.pausePlotting = 0;
                    if isequal(r,2)
                        continueAutomatically = 1;
                    end
                end
            end
        end
           
        trial.saccades = saccades;
        
    end

end
