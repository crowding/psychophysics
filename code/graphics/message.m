function f = message(details, varargin)
%function f = message(details, varargin)
%throw up an informative message in the middle of the screen and flips the
%screen. Requires that you have an open screen, naturally.
%
%varargin is to be processed using sprintf().

string = sprintf(varargin{:});

%just use the default text style

Screen('FillRect', details.window, details.backgroundIndex);
bounds = Screen('textBounds', details.window, string);
center = sum(details.rect([1 2;3 4])) ./ 2;
offset = sum(bounds([1 2; 3 4])) ./ 2;
origin = center - offset;

Screen('DrawText', details.window, ...
    string, origin(1), origin(2), ...
    details.foregroundIndex, details.backgroundIndex);

Screen('Flip', details.window);