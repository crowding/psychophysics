function tex = texture_movie(this, w, cal);
% function tex = texture_movie(this, w, cal);
%
% Create the texture movie for vernier alignment.
% Return a vector of structs t with fields:
% 
% t.texture (the texture to play)
% t.playrect (the rectangle to play it in)
% t.frame (the frame number to show it on)
% 
% The entries are sorted with t.frame in ascending order.

offset = [this.ddx this.ddy this.ddt];
motion1 = ApparentMotion(...
				'primitive', this.primitive, ...
				'center', this.center + offset./2, ...
				'dx', this.dx, ...
				'dt', this.dt, ...
				'n', this.n);
				
motion2 = ApparentMotion(...
				'primitive', this.primitive, ...
				'center', this.center - offset./2, ...
				'dx', this.dx, ...
				'dt', this.dt, ...
				'n', this.n);

if (this.ddp) ~= 0
	motion1.primitive.phi = motion1.primitive.phi + this.ddp/2;
	motion2.primitive.phi = motion2.primitive.phi - this.ddp/2;
end

t = rowmap(@(p) texture_movie(p, w, cal), [motion1 motion2]);

[a indices] = sort([t.frame]);
tex = t(indices);
