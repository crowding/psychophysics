function ax = cogplot(rings, cogs, radius)
%function ax = cogplot(rings, cogs, radius)
%Given a list of chainring sizes, a list of cog sizes, and the wheel
%radius in mm, plots all available gear ratios and the percentage jumps
%between them, on a log-log scale. Each gerchage is plotted as a line,
%green fir single shift, orange for double shift, red for triple shift.
%Double/triple shifts are omitted if another shift is closer


rings = sort(rings); cogs = sort(cogs);
[gring, gcog] = ndgrid(rings, cogs);
[ringix, cogix] = ndgrid(1:numel(rings), 1:numel(cogs));

gearinches = gring .* (1./gcog) * radius * 2 / 25.4;

%Plot all gear ratios, and draw a dotted line through along each set of
%ratios given by each rear cog a dotted line.
margin = 1.2; % the margin on left and right sides(log units)
[ax, h1, h2] = plotyy( gring(:), gearinches(:) ...
    , [gring(1,:) ./margin; gring(end,:).*margin] ...
    , [gearinches(1,:)./margin; gearinches(end,:).*margin] ...
    );
set(h1, 'Marker', '.', 'LineStyle', 'none', 'Color', 'k');
set(h2, 'Color', [0.8 0.8 0.8], 'LineStyle', ':');

ylabel(ax(1), 'Gear inches'); 
xlabel(ax(1), 'Rings'); 
set( ax(1) ...
    , 'YScale', 'log' ...
    , 'XScale', 'log' ...
    , 'XTick', rings ...
    , 'YTick', [15 20 25 30 35 40 50 60 70 80 100 120 140] ...
    );

%Match the scale on both axes, and label tickmarks for the dotted line
%with each cog's tooth count.
ylabel(ax(2), 'Cogs')
set( ax(2)...
    , 'Position', get(ax(1), 'Position')...
    , 'YScale', get(ax(1), 'YScale')...
    , 'XScale', get(ax(1), 'XScale')...
    , 'XLim', get(ax(1), 'XLim')...
    , 'YLim', get(ax(1), 'YLim')...
    , 'XTick', [] ...
    , 'TickDir', 'out' ...
    , 'YTick', gearinches(end,end:-1:1).*margin...
    , 'YTickLabel', arrayfun(@num2str, cogs(end:-1:1), 'UniformOutput', 0)...
    );

%now for each gear find the closest neighbors (that are higher)
hold(ax(1), 'on');
for ix = [gearinches(:) ringix(:) cogix(:)]'
    gi = ix(1);
    rix = ix(2);
    cix = ix(3);
    
    %neighbors accessible by a 'reasonable' shift (at most one ring and two
    %cogs)
    neighbors = [...
        rix-1 cix-2; rix-1 cix-1; rix-1 cix; ...
        rix cix-1; ...
        rix+1 cix; rix+1 cix+1; rix+1 cix+2 ];
    % ; rix+1 cix+2
    neighbors = neighbors ...
        ( (neighbors(:,1) >= 1) & (neighbors(:,1) <= numel(rings)) ...
        & (neighbors(:,2) >= 1) & (neighbors(:,2) <= numel(cogs)) ...
        , :);
    
    neighbors = [gearinches(sub2ind(size(gearinches), neighbors(:,1),neighbors(:,2))) neighbors];
    %only count upshifts...
    neighbors = neighbors(neighbors(:,1) > gi,:);
    
    neighbors = sortrows(neighbors);

    %and only count the first upshift found on each ring.
    [tmp, i] = unique(neighbors(:,2), 'first');
    neighbors = neighbors(i,:);
    
    %plot each with a percentage change...
    colors = [0 1 0; 1 0.7 0; 1 0.2 0.2];
    for jx = neighbors'
        distance = abs(cix-jx(3)) + abs(rix-jx(2));
        pct = (jx(1)/gi - 1) * 100;
        plot(ax(1), [rix jx(2)], [gi jx(1)], '-', 'Color', colors(distance,:));
        h = text((rix+jx(2))/2, (gi+jx(1))/2, sprintf('%.2g%%', pct));
        set(h, 'HorizontalAlignment', 'center', 'BackgroundColor', 'w')
    end
end
hold(ax(1), 'off');