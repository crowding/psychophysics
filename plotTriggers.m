function ax = plotTriggers(fig, params, trigger)
    %plot the triggers from an eye movement trial, for diagnostic purposes.
    figure(fig);
    
    d = params.input.eyes.getData();
    d([1 2],:) = repmat(params.input.eyes.getOffset(), 1, size(d,2)) + params.input.eyes.getSlope() * d([1 2],:);
    e = trigger.getEvents();

    cla;
    hold on;

    %x- any y- locations of the trace
    onset_ = e{1,1};
    
    plot(d(3,:) - onset_, d(1,:), 'r-', d(3,:) - onset_, d(2,:), 'b-');
%    plot(0, fixationPointLoc(1), 'ro', 0, fixationPointLoc(2), 'bo')
    %       plot(targetOnset, fixationPointLoc(1) + cos(targetPhase) * targetRadius, 'rx', targetOnset, fixationPointLoc(2) - sin(targetPhase) * targetRadius, 'bx')
    ylim([-15 15]);

    %draw labels...
    %what height should we draw text at
    labels = regexprep(e(:,2), '.*/', '');
    times = [e{:,1}]' - onset_;
    if numel(d(3,~isnan(d(1,:)))) >= 2
        heights = interp1(d(3,~isnan(d(1,:))) - onset_, max(d(1,~isnan(d(1,:))), d(2,~isnan(d(1,:)))), times, 'linear', 'extrap');
    else
        heights = zeros(size(times));
    end
    t = text(times, heights+1, labels, 'rotation', 90);
    %make sure the graph is big enough to hold the labels
    %this doesn't deal well with rotation.../
    %        xs = get(t, 'Extent');
    %        mn = min(cat(1,xs{:}));
    %        mx = max(cat(1,xs{:}));
    %        ylim([min(-15, mn(2)) max(15, mx(2) + mx(4))]);
    hold off;
    drawnow; 
end
