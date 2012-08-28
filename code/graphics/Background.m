function this = Background(color__)

%The background rectangle.

%----- public interface -----
this = finalize(inherit(...
    Drawer(),...
    objProperties('visible', 0, 'color', color__),...
    public(@draw)...
    ));

%----- methods -----

%FIXME: this simple kind of accessor creation is why public() needs to
%make a class supporting subsref() and subsasgn() and provide public
%properties - a 'properties'
%struct-generating function as the argument to public() would do the trick
%for a calling convention.
%Inheritance/mixins wouldn't hurt either.

    function draw(window, next)
        if this.getVisible()
            Screen('FillRect', window, this.getColor());
        end
    end
end
