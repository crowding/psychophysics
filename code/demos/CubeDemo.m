function CubeDemo(varargin)

params = namedargs...
    ( 'requireCalibration', 0 ...
    , varargin{:});

%trig = Trigger();
%keyb = KeyboardInput();

main = mainLoop...
    ( 'input', {} ...
    , 'triggers', {} ...
    , 'graphics', {SpinningCube()} ...
    );

%trig.singleshot(atLeast('refresh', 100), main.stop);

%trig.singleshot(keyIsDown('q'), main.stop);
    
require(getScreen(params), main.go);