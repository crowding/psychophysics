function [x, y, t, xi, yi, ti] = sampling(dispatch, this, cal, oversample)
%function [x, y, t, xi, yi, ti] = sampling(dispatch, this, cal)
%
% Compute appropriate points for sampling this function when computing a movie.
% You can override this for more speed in e.g. a bar stimulus so that the 
% function is only computed near its edges.
%
% The 'dispatch' argument is required due to yet another fundamental failing in 
% how MATLAB implements classes. I need to implement subclasses that 
% both overload 'sampling' and call this base class's 'sampling'. But this 
% base class's 'sampling' depends on 'extent' and 'resolution' which are
% implemented by subclasses. Therefore the following:
%
% sampling(this.Patch, cal)
%
% will not work as a way for a thisclass to delegate to this base class. The 
% solution here is to add the 'dispatch' argument and write
%
% sampling(dispatch.Patch, this, cal)
%
% in subclasses.
%
% Now all the outputs. "xi, yi, ti" give the boundaries of the region over
% which the things is sampled. 'x', 'y', 't' gove the actual locations you
% should take a sample at. This usually means that x, y, are halfway
% between pixels,  while xi and yi are at the pixel boundaries (See this
% diagram of the screen pixels:
%
%    0--------*--------*
%    |        |        |
%    |        |        |
%    |        |        |
%    *--------*--------*
%    |        |        |
%    |        |        |
%    |        |        |
%    *--------*--------*
%
% If the point marked 0 is the origin, and we want to evaluate over the
% region shown, then xi = [0, 2], yi = [0, 2], x = [0.5, 1.5], yi = [0.5,
% 1.5] (i.e. we evaluate at the centers of pixel squares. Do you get it? It's a
% fencepost thing.
%
% Since 'time' is assumed to flash each frame instantaneously as a pulse,
% we can ignore such subtleties.
%
% If you provide the 'oversample' parameter and set it to a whole number,
% we will pretend the display has more pixels than it does (this may come in
% handy for more accurate display of rotated or scaled sprites.)
blocksize = 16;

[xi, yi, ti] = extent(this);

%Calibration gives the pixel locations...
toPixels = transformToPixels(cal);
toDegrees = transformToDegrees(cal);
[xip, yip] = toPixels(xi, yi);

%assume t=0 always falls on a frame boundary.
tif = ti ./ cal.interval;

%A patch can have a 'resolution' parameter that says how finely to
%sample. The sample spacing is then the worst of: a whole number multiple
%of the sampling resolution, or the device resolution.(multiples for
%antialiasing purposes.)

nativeSpacing = [spacing(cal) cal.interval];
desiredSpacing = resolution(this);
desiredSpacing = nativeSpacing .* floor(desiredSpacing./nativeSpacing);
sampleSpacing = max(desiredSpacing, nativeSpacing);

%Bring xi, yi, ti to the pixel/frame boundaries in any case.
xip(1) = floor(xip(1));
yip(1) = floor(yip(1));
tif(1) = floor(tif(1));

%go back to degree/second units...
[xi, yi] = toDegrees(xip, yip);
ti = tif .* cal.interval;

%now bring the upper bounds to the sampling-resolution-determined
%boundaries, modulo blocksize...
xi(2) = xi(1) + ceil((xi(2)-xi(1)-sampleSpacing(1)) / sampleSpacing(1)/blocksize) * sampleSpacing(1)*blocksize;
yi(2) = yi(1) + ceil((yi(2)-yi(1)-sampleSpacing(2)) / sampleSpacing(2)/blocksize) * sampleSpacing(2)*blocksize;
ti(2) = ti(1) + ceil((ti(2)-ti(1)) / sampleSpacing(3)) * sampleSpacing(3);

%sampling! now sample things. The samples fall in the middle of boundaries
%established by the spacing. Except for temporam sampling, which is
%instantaneous.
x = linspace(xi(1) + sampleSpacing(1)/2, xi(2) - sampleSpacing(1)/2, round((xi(2)-xi(1)) / sampleSpacing(1)));
y = linspace(yi(1) + sampleSpacing(2)/2, yi(2) - sampleSpacing(2)/2, round((yi(2)-yi(1)) / sampleSpacing(2)));
t = linspace(ti(1), ti(2), round((ti(2)-ti(1)) / sampleSpacing(3)) + 1);
    
end