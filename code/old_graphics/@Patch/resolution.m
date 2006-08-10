function r = resolution(this)
% Return the mimimum useful distance between sample points. The default of 
% 0 means the natural display sampling size will be used. The sampling size
% used to construct the stimulus will be the smallest integer multiple of 
% the pixel spacing larger than this value.
%
% Nonzero values for temporal resolution are not yet supported.
r = [0 0 0];
