function this = makeCurrentAxes(ax)

%makes the axis and the figure containing it current WITHOUT raising it to
%the foreground. Sheesh.

fig = ancestor(ax, 'figure'); %i can't make ancestor work????
if ~isempty(fig)
    set(0, 'CurrentFigure', fig);
    set(fig, 'CurrentAxes', ax);
else
    %ffs, why won't ancestor work on my laptop?
    axes(ax);
end