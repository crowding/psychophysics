function tex = texture_movie(this, w, cal);
% function tex = texture_movie(this, w, cal);
%
% Create the texture movie for flash lag.
% Return a vector of structs t with fields:
% 
% t.texture (the texture to play)
% t.playrect (the rectangle to play it in)
% t.frame (the frame number to show it on)
% 
% The entries are sorted with t.frame in ascending order.

motion = texture_movie(this.ApparentMotion, w, cal)
		
flash = this.flash;

station_offset = (-this.ApparentMotion.n/2 + this.when - 1) .* ...
	[this.ApparentMotion.dx, 0, this.ApparentMotion.dt];
flash_center = this.ApparentMotion.center + flash.center + station_offset + ...
	[this.ddx, this.ddy, this.ddt];

flash.center = flash_center;
flashmovie = texture_movie(flash, w, cal);

t = [motion flashmovie];
[a indices] = sort([t.frame]);
tex = t(indices);
