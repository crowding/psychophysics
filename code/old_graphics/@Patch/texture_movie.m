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

[z, x, y, t] = movie(this, cal);

%the playrect in pixels
center = floor(get(cal, 'rect') * [0.5 0; 0 0.5; 0.5 0; 0 0.5]);
native = [spacing(cal) cal.interval];
rect = round([x(1) y(1) x(end) y(end)] ./ native([1 2 1 2]));
rect = rect + center([1 2 1 2]);

interval = get(cal, 'interval');

black = BlackIndex(w);
white = WhiteIndex(w);
gray = black + white / 2;
inc = white - gray;

%make textures
tex = cell(size(z, 3), 1);
for i = 1:numel(tex)
    %find a bounding rectangle to use.
    pic = z(:, :, i);
    
    [r1, r2, c1, c2] = nonzero_rect(pic);
    
	pic = gray + pic(r1:r2,c1:c2) .* inc;
    if ~isempty(pic)
    	tex{i} = struct(...
        	'texture', Screen('MakeTexture', w, pic), ...
            'playrect', ...
                round([x(c1) y(r1) x(c2) y(r2)] ./ native([1 2 1 2]))...
                + center([1 2 1 2]),...
    		'frame', i ,...
            'time', t(i) );
    end
end

%eliminate empties and make into struct array
tex = cat(1, tex{:});

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