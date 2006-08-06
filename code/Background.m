function this = Background(color_)

%The background rectangle.

%----- public interface -----
this = inherit(...
    Drawer(),...
    public(@color, @setColor, @draw)...
    );

%----- methods -----

%FIXME: this simple kind of accessor creation is why public() needs to
%make a class supporting subsref() and subsasgn() and provide public
%properties - a 'properties'
%struct-generating function as the argument to public() would do the trick
%for a calling convention.
%Inheritance/mixins wouldn't hurt either.

    function c = color
        c = color
    end

    function setColor(newcolor)
        color_ = newcolor;
    end

    function draw(window)
        if this.visible()
            Screen('FillRect', window, color_);
        end
    end
end