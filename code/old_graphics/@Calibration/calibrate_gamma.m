function this = calibrate_gamma(this)

% calibrate the gamma function for the attached display.

readings = calibrate_osx(this.screenNumber);

% for testing purposes use a saved measurement:
%dirs = env;
%gammafile = fullfile(dirs.calibrationdir, 'calibration.mat');
%readings = load(gammafile, 'readings');
%readings = readings.readings;

% plot the measurement
clf;
hold on;
plot(readings(:,1), readings(:,2), 'k-');

%smooth the measurement by a little diffusion

smoothed = readings;
for (i = 1:5)
	smoothed(2:end-1,2) = smoothed(2:end-1,2)/2 + ...
				(smoothed(1:end-2,2) + smoothed(3:end,2))/4;
end

%check for monotonicity
if any(smoothed(2:end) < smoothed(1:end-1))
	warning('measured gamma function is not monotonic');
end
plot(smoothed(:,1), smoothed(:,2), 'b-');

%We want linear range
range = linspace(min(smoothed(:,2)), max(smoothed(:,2)), 256);

%remove readings that duplicate values (for the beginning tail of x=0)
smoothed = sortrows(smoothed, 2);
smoothed(find(diff(smoothed(:,2)) == 0)+1,:) = [];

%Interpolate the inverted function
gamma = interp1(smoothed(:,2), smoothed(:,1), range, 'spline');

%plot to show the linearity
plot( 0:255, interp1(smoothed(:,1), smoothed(:,2), gamma, 'spline'), 'r-');

hold off;

%normalize the color table
gamma = gamma / max(readings(:,1));

this.gamma = makecolumn(gamma) * [1 1 1];
this.measured = true;
