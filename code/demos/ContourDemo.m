function this = ContourDemo(varargin)
    
    params = struct...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 0  ...
        , 'requireCalibration', 0 ...
        , 'hideCursor', 0 ...
        , 'aviout', '' ...
        , 'input', struct('keyboard', keyboardInput()) ...
        , 'priority', 0 ...
        );

    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    spacing = 0.25;
    wavelength = 0.25;
    width = 0.25;
    jitter = 0.1;
    bounds = [-15 -15 15 15];
    color = [1/10;1/10;1/10];
    levels = 5;

    source = StaticSource('color', [1/8 1/8 1/8]');
    field = CauchyDrawer('visible', 1, 'source', source);
    fixation = FilledDisk('loc', [0;0], 'color', [0;0;0], 'radius', 0.1, 'visible', 1);
    
    reshuffle();
    
    function result = run(params)
        t = Trigger();
        kb = KeyDown();
        
        main = mainLoop...
            ('graphics', {field, fixation} ...
            , 'triggers', {t, kb} ...
            , 'input', params.input.keyboard);
        
        kb.set(main.stop, 'ESCAPE');
        kb.set(@reshuffle, 'space');
        
        result = struct();
        
        main.go(params);
    end
 
    function reshuffle(h)
        %space a hex grid...
        for i = 1:levels
            sp = 2.^(log2(spacing)+i-1);
            xy{i} = hexgrid(bounds, sp);
            xy{i} = xy{i} + randn(size(xy{i}))*jitter*2.^(i-1);
            l{i} = zeros(1, size(xy{i}, 2)) + wavelength*2.^(i-1);
            c{i} = color(:, ones(1,size(l{i},2)));%./2.^(i-1);
            w{i} = width(:, ones(1,size(l{i},2))).*2.^(i-1);
        end
        
        xy = [xy{:}];
        l = [l{:}];
        c = [c{:}];
        w = [w{:}];
        
        source.setLoc(xy);
        source.setWavelength(l);
        source.setColor(c);
        source.setWidth(w);
        
        angle = rand(1, size(xy, 2)) * 360;
        source.setAngle(angle);
        phase = rand(size(angle)) * 2 * pi;
        source.setPhase(phase);
    end

    demo(varargin{:});
        
    function p = demo(varargin)
        p = namedargs(localExperimentParams(), params, varargin{:});
        p.input = struct('keyboard', p.input.keyboard);
        p = require(p, getScreen(), @initInput, @run);
        params = p;
    end
end

function [release, params, next] = initInput(params)
    rescs = struct2cell(structfun(@(x)x.init,params.input, 'UniformOutput', 0));
    i = joinResource(rescs{:});
    next = i;
    release = @noop;
end

function xy = hexgrid(bounds, spacing)
    startrow = ceil(bounds(2)/(spacing*sqrt(3)/2));
    endrow = floor(bounds(4)/(spacing*sqrt(3)/2));
    
    x = [];
    y = [];
    for i = startrow:endrow
        if mod(i,2) == 1
            xs = ceil(bounds(1)/spacing)*spacing:spacing:floor(bounds(3)/spacing)*spacing;
        else
            xs = (ceil(bounds(1)/spacing-0.5)+0.5)*spacing:spacing:(floor(bounds(3)/spacing-0.5)+0.5)*spacing;
        end
        x = [x xs];
        y = [y i*spacing*sqrt(3)/2 + zeros(size(xs))];
    end
    xy = [x;y];
end
