function this = MouseDown(varargin)
%Mouse trigger fires when a mouse button is depressed.

log = @noop;
fntable = {};

persistent init__;
this = autoobject(varargin{:});

lastButtons_ = [];

%------methods
    function [release, params] = init(params)
        [tmp1, tmp2, lastButtons_] = GetMouse(params.window);
        if numel(fntable) < numel(lastButtons_)
            fntable(numel(lastButtons_)) = {[]};
        end
        release = @noop;
    end

    function m = check(m)
        b = m.mouseButtons & ~lastButtons_;
        if any(b)
            m.buttonsDown = b;
            for i = fntable(b)
                if ~isempty(i{1})
                    log('TRIGGER %s %s', func2str(i{1}), struct2str(m));
                    i{1}(m);
                end
            end
            lastButtons_ = m.mouseButtons;
        end
    end


    function set(fn, button)
        if nargin >= 2
            [fntable{button}] = deal(fn);
        else
            [fntable{:}] = deal(fn);
        end
    end


    function unset(button)
        if nargin >= 1
            [fntable{button}] = deal([]);
        else
            [fntable{:}] = deal([]);
        end
    end
end