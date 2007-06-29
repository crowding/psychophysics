function this = MouseDown(varargin)
%Mouse trigger fires when a mouse button is depressed.

this = autoobject(varargin{:});
fntable = {};

lastButtons_ = [];

    function [release, params] = init(params)
        [tmp1, tmp2, lastButtons_] = GetMouse(params.window);
        fntable = cell(size(lastButtons));
        release = @noop;
    end

    function check(m)
        b = m.buttons & ~lastButtons_;
        if any(b)
            m.buttonsDown = b;
            for i = fntable(b)
                if ~isempty(i{1})
                    i{1}(m);
                end
            end
            lastButtons_ = m.buttons;
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