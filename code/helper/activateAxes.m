function activateAxes(ax)
%activate an axis for drawing commands WITHOUT bringing its window to the
%front or otherwise seizing hte user interface.

parent_figure = ancestor(ax, 'figure');
activateFigure(parent_figure);
set(parent_figure, 'CurrentAxes', ax);