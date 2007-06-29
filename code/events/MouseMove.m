function this = MouseMove(varargin)
%Mouse trigger fires when the mouse is moved.

log = @noop;
fn = [0 0];
relative = 0; %this will reset the mouse position to the screen center every time

%we require this information on initialize
window_ = NaN;
center_ = NaN; %the center of the screen...
last_ = [];
isSet_ = 0;

this = autoobject(varargin{:});

    function [release, params] = init(params)
        window_ = params.window;
        degreesToPixels = transformToPixels(params.cal) * 2;
        center_px_ = degreesToPixels([0 0]);
        
        %For the move distance all we need is a linear scaling
        release = @unhide;
    end

    function check(m)
        %if the mouse has moved...
        if isSet_ && ((last_.x ~= m.x) || (last_.y ~= m.y))
            if relative
                %reset mouse to center
                SetMouse(center_(1), center_(2), window_);
            end
            m.prevx = last_.x;
            m.prevy = last_.y;
            m.movex = m.x - last_.x;
            m.movey = m.y - last_.y;
            m.movex_deg = m.x_deg - last_.x_deg;
            m.movey_deg = m.y_deg - last_.y_deg;

            log('MOUSE_MOVE %s %s', func2str(fn), struct2str(m));
            fn(m);
            if relative
                m.x = 0;
                m.y = 0;
                m.x_deg = 0;
                m.y_deg = 0;
            end
        end
        last_ = m;
    end

    function set(fn_)
        fn = fn_;
        isSet_ = 1;
    end

    function unset()
        isSet_ = 0;
    end
end