function tex = texture_movie(this, w, cal);
% function tex = texture_movie(this, w, cal);
%
% Return a vector of structs t with fields:
% 
% t.texture (the texture to play)
% t.playrect (the rectangle to play it in)
% t.frame (the frame number to show it on, first frame being 1)
% t.time (the time of the frame w.r.t the object's center)
% 
% The entries are sorted with t.frame in ascending order. Note that frames
% that are all zero will not be made into textures - need to check for them
% in your playback routines.
FUNC_ADD_EXT = hex2dec('8006');
FUNC_REVERSE_SUBTRACT_EXT = hex2dec('800B');

[z, x, y, t, xi, yi, ti] = movie(this, cal);

%the playrect in pixels
toPixels = transformToPixels(cal);
playrect = toPixels([xi(1) yi(1) xi(2) yi(2)]);

black = BlackIndex(w);
white = WhiteIndex(w);
gray = black + white / 2;
inc = white - gray;

%initialize a texture array
tex(size(z, 3) * 2) = struct...
            ( 'texture', [] ...
            , 'playrect', [] ...
    		, 'frame', [] ...
            , 'time', [] ...
            , 'sourceFactor', [] ...
            , 'destFactor', [] ...
            , 'blendEquation', [] ...
            );

j = 1;
for i = 1:size(z, 3)
    
    pic = z(:, :, i);
    
%{
    %this was useful earlier, but needs to be updated for the sampling.m
    %rewrite.
    %find a bounding rectangle to use.
    [r1, r2, c1, c2] = nonzero_rect(pic);
    pic = pic(r1:r2,c1:c2) .* inc;
%}
    
    %split texture into positive and negative components
    ppic = pic * inc;
    npic = -pic * inc;
    ppic(ppic < 0) = 0;
    npic(npic < 0) = 0;
    
    if ~isempty(ppic)
    	tex(j) = struct ...
            ( 'texture', Screen('MakeTexture', w, ppic) ...
            , 'playrect', playrect ...
    		, 'frame', i ...
            , 'time', t(i) ...
            , 'sourceFactor', GL_ONE ...
            , 'destFactor', GL_ONE ...
            , 'blendEquation', FUNC_ADD_EXT ...
            );
        j = j + 1;
    end
        
    if ~isempty(npic)
        tex(j) = struct...
            ( 'texture', Screen('MakeTexture', w, npic) ...
            , 'playrect', playrect ...
    		, 'frame', i ...
            , 'time', t(i) ...
            , 'sourceFactor', GL_ONE ...
            , 'destFactor', GL_ONE ...
            , 'blendEquation', FUNC_REVERSE_SUBTRACT_EXT ...
            );
        j = j + 1;
    end
end

%eliminate empties
tex(j:end) = [];

function [rowmin, rowmax, colmin, colmax] = nonzero_rect(array)
    %returns the enclosing row and column indices of the nonzero elements
    %of an array. 
    rows = find(any(array, 2));
    cols = find(any(array, 1));
    if ~isempty(rows)
        rowmin = rows(1);
        rowmax = rows(end);
        colmin = cols(1);
        colmax = cols(end);
    else
        rowmin = 1;
        rowmax = 0;
        colmin = 1;
        colmax = 0;
    end
end

end