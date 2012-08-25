function this = motionChangeBlindnessDemo(varargin)

%here we recreate the motion change blindness demo
%A number of spots appear in an annulus, then they start moving. Then they
%stop.

%two major things to try:

%is the crowding of multiple adjacent targets necessary? try making up that
%"horseshoe-gradual-density" demo.

%is the coherent motion necessary? what about if targets move in different
%directions? (is there a good way they can all move different directions --
%sime kind of peano space-time-filling curve?)

%can we measure this via a change reaction task? two interval forced choice
%on which interval a (cued) spot changed in? 

oscExcursion = 1; %1 radian
oscFrequency = 1; %in natural trigonometric units.
oscillations = 3; %any multiple of 0.5 is acceptable.

delayBeforeOsciallation = 3;
delayAfterOscillation = 3;
spotRadius = 0.1;
spotGenerator = spotPositions();
this = autoobject(varargin{:})

function this = spotPositions(varargin)
    %we start by simulated-annealing randomly distributed spots into position.
    annulusInner = 3;
    annulusOuter = 5;
    n = 1000;
    spotForcingFunction = (r)max(r, 0);
    wallMultiplier = 4;
    spotNoiseFunction = @(n) 0.01 / 100;
    persistent this__;
    this = autoobject(varargin);
    
    %luckily, I already have a random number generator for an even
    %distribution over an annulus.
    function [x, y] = generate(this)
        source = AnnularDotProcess('bounds', [0 0 annulusInner annulusOuter])
        pos = zeros(2, n);
        for i = 1:n
            [pos(1,i), pos(2,i)] = source.next();
        end
        plot(pos(1,:), pos(2,:), 'k.');
    end
end

