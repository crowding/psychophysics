function r = match(this, that);
% function r = match(this, that)
% 
% returns 1 if the two calibrations given as arguments refer to the same 
% equipment setup. Compares machine name, screen number, screen resolution, and 
% frame rate.

r = 1;
r = r && strcmp(this.machine, that.machine);
r = r && this.screenNumber == that.screenNumber;
r = r && all(this.rect == that.rect);
r = r && this.interval == that.interval;
