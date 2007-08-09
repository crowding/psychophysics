function [data, x, y, t, f] = importQT(filename, xrange, yrange, frange)
%function [data, x, y, t, f] = importQT(filename, xrange, yrange, frange)
%an enormous kludge for importing quicktime movies into matlab.

    if ~exist('xrange', 'var')
        xrange = [];
    end
    if ~exist('yrange', 'var')
        yrange = [];
    end
    if ~exist('frange', 'var')
        frange = [];
    end

    params = require(getScreen('requireCalibration', 0, 'preferences.skipSyncTests', 1) ...
        , currynamedargs(@openMovie, 'moviefile', filename) ...
        , currynamedargs(@importMovie, 'xrange', xrange, 'yrange', yrange, 'frange', frange) ...
        );

    data = params.data;
    x = params.xrange;
    y = params.yrange;
    f = params.frange;
    t = (params.frange - 1) / params.fps;
end

function [release, params] = openMovie(params)
    [params.moviePtr, params.duration, params.fps, params.width, params.height, params.count] = ...
        Screen('OpenMovie', params.window, params.moviefile);
    
    release = @() Screen('CloseMovie', params.moviePtr);
end

function params = importMovie(params)
    if isempty(params.xrange)
        params.xrange = 1:params.width;
    end
    if isempty(params.yrange)
        params.yrange = 1:params.width;
    end
    if isempty(params.frange)
        params.frange = 1:params.count;
    end
    
    out = zeros(numel(params.xrange), numel(params.yrange), 3, numel(params.frange), 'uint8');
    
    for frame = [params.frange(:)'; 1:numel(params.frange)]
        [frame, frameix] = deal(frame(1), frame(2));
        out(:, :, :, frameix) = require(currynamedargs(@getMovieFrameTexture, params, 'frame', frame), @extractMovieFrame);
    end
    params.data = out;
end

function [release, params] = getMovieFrameTexture(params)
    [params.texture, params.timeix] = Screen('GetMovieImage', params.window, params.moviePtr, 0, (params.frame - 1) / params.fps);
    if (params.texture == 0)
        [params.texture, params.timeix] = Screen('GetMovieImage', params.window, params.moviePtr, 1, (params.frame - 1) / params.fps);
    elseif params.texture == 1
        error('importQT:noframe', 'no frame here');
        return;
    end
    %show it on the screen
    %capture it from the screen
    release = @() Screen('Close', params.texture);
end

function image = extractMovieFrame(params)
    Screen('DrawTexture', params.window, params.texture, [], [0 0 params.width params.height]);
    Screen('Flip', params.window);
    coords = [min(params.yrange)-1 min(params.xrange)-1 max(params.yrange) max(params.xrange)];
    image = Screen('GetImage', params.window, coords);
    image = image(params.xrange - min(params.xrange) + 1, params.yrange - min(params.yrange) + 1, :);
end

