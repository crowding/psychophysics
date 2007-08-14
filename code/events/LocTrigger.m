function this = LocTrigger(varargin)
%An object that fires a trigger when x and y is within a certain distance
%to a point.

fn = @noop;
loc = @()[0 0];
in = 0;
radius = 0;
offset = [0 0];
log = @noop;

set_ = 0;

this = autoobject(varargin{:});

    function check(s)
        if set_ && xor((norm([s.x s.y] - loc() - offset) >= radius), in)
            log('TRIGGER %s %s', func2str(fn), struct2str(s));
            fn(s); %call function when eye is inside
        end
    end
    
    function set(fn_, in_, radius_, offset_)
        if (nargin == 4)
            fn = fn_;
            in = in_;
            radius = radius_;
            offset = offset_;
        end
        set_ = 1;
    end

    function unset()
        set_ = 0;
    end

    function draw(window, toPixels)
        if set_
            l = loc();
            Screen('FrameOval', window, [255*(~in) 255*(~~in) 0],...
                toPixels([l l] + [offset offset] + radius*[-1 -1 1 1]) );
        end
    end

end