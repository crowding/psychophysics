function r = spacing(this)
% function r = spacing(this);
% returns the number of degrees per pixel (2-element vector).
r = this.spacing ./ this.distance * 180 / pi;
