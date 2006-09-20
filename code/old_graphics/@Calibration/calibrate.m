function this = calibrate(this, varargin)

% calibrate the gamma function after performing a measurement. the optional
% background_color option is the assumed background color of the display,
% and defaults to 0.5.

defaults = struct( ...
      'date', date ...
    , 'desired_background', 0.5 ...
    , 'stage1_points', 50 ...
    , 'stage2_points', 256 ...
    , 'stage1', struct('screenNumber', this.screenNumber)...
    , 'stage2', struct('screenNumber', this.screenNumber)...
    );
params = namedargs(defaults, varargin{:});


%ask for distance measurements
distance = input(sprintf('eye to screen distance in cm [%f]', this.distance));
if ~isempty(distance)
    this.distance = distance;
end

xspacing = input(sprintf('width of screen in cm [%f]', this.spacing(1) * this.rect(3)));
xspacing = xspacing / this.rect(3);
if ~isempty(xspacing)
    this.spacing(1) = xspacing;
end

yspacing = input(sprintf('height of screen in cm [%f]', this.spacing(2) * this.rect(4)));
yspacing = yspacing / this.rect(4);
if ~isempty(yspacing)
    this.spacing(2) = yspacing;
end

%----- perform stage one measurements -----
%measure white foregrounds, black foregrounds, and full fields
fore = [zeros(1, params.stage1_points) ones(1, params.stage1_points) linspace(0, 1,params.stage1_points)]';
back = repmat(linspace(0, 1, params.stage1_points), 1, 3)';
%remove duplicates
back(1) = []; back(end) = []; fore(1) = []; fore(end) = [];

%the photometer has a settling/autorange time, but I want to keep the monitor's power
%supply warm. Therefore I shuffle the background while increasing the
%foreground monotonically.
r = randperm(numel(back));
back = back(r);
fore = fore(r);
[fore, i] = sort(fore);
back = back(i);

params.stage1 = measure(...
      params.stage1 ...
    , 'background', back ...
    , 'foreground', fore ...
    , 'photometer_size', 9.5 / min(this.spacing) ...
    );

%average the separate readings if there is more than 1
z = params.stage1.readings;

%plot the measurement...
clf;
hold on;
axis vis3d;
axis square;
tri = delaunay(back, fore);
trisurf(tri, back, fore, z, 'Cdata', permute([0.75 0.75 0.75], [3 1 2]), 'BackFaceLighting', 'lit');
view(3);
lighting gouraud;
camlight left;
xlabel('Background value');
ylabel('Foreground value');
zlabel('Luminance');
noop;

%the process griddata below was originally writen for sampling the
%entire grid of background and foreground values, but should work fine for
%my more specific sampling (the interpolation finds values that it already
%took.)

%find luminous values with white foregrounds
white_i = find(fore == 1);
[inputs, i] = sort(back(white_i));
whitevals = z(white_i(i));
plot3(inputs, ones(size(inputs)), whitevals, 'b-', 'LineWidth', 3);

%as well as values with black foregrounds 
blackvals = griddata(back, fore, z, inputs', 0, 'cubic')';
plot3(inputs, zeros(size(inputs)), blackvals, 'r-', 'LineWidth', 3);

%and the values with even fields (back = fore)
fullvals = diag(griddata(back, fore, z, inputs', inputs, 'cubic'));
plot3(inputs, inputs, fullvals, 'w-', 'LineWidth', 3);

%find the full field intensity that splits black and white intensities
%evenly
split = (fullvals - blackvals) ./ (whitevals - blackvals);
[split, splinputs] = distinctx(split, inputs);
gray = interp1(split, splinputs, params.desired_background);


%Now capture a full gamma curve for the gray background

%%when working off a grid...
%grayvals = griddata(back, fore, z, gray, linspace(0,1,1024), 'cubic');
%plot3(zeros(1, 1024) + gray, linspace(0,1,1024), grayvals, 'k-', 'LineWidth', 6);

%when measuring on the fly...
params.stage2 = measure(...
      params.stage1 ... %to pass on the photometer location and sampling
    , params.stage2 ...
    , 'background', zeros(1, params.stage2_points) + gray ...
    , 'foreground', linspace(0, 1, params.stage2_points) ...
    );
s2inputs = params.stage2.foreground;
s2vals = params.stage2.readings;

%and invert it
s2vals = sort(s2vals); %clean up, assuming monotonicity
[s2vals, s2inputs] = distinctx(s2vals, s2inputs);

gammacurve = interp1(s2vals, s2inputs, linspace(min(s2vals),max(s2vals),256), 'cubic');

%visual check - this should overlap the red line
plot3(zeros(1, 256) + gray, gammacurve, linspace(min(s2vals),max(s2vals), 256), 'g-', 'LineWidth', 2);

this.gamma = repmat(gammacurve(:), 1, 3);
this.calibrated = 1;

this.calibration = params();
rotate3d on;


hold off;