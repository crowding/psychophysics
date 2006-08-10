function tex = texture_movie(this, w, cal);
% function tex = texture_movie(this, w, cal);
%
% Return a vector of structs t with fields:
% 
% t.texture (the texture to play)
% t.playrect (the rectangle to play it in)
% t.frame (the frame number to show it on)
% 
% The entries are sorted with t.frame in ascending order.

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
for i = 1:size(z,3)
	pic = gray + z(:,:,i) .* inc;
	tex(i) = struct(...
		'texture', Screen('MakeTexture', w, pic), ...
		'playrect', rect, ...
		'frame', t(i) ./ interval);
end

