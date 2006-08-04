function this = Background(initColor)

%The background rectangle.

%----- public interface -----
this = public(...
     @drawer... %the drawer interface
    ,@color...
    ,@setColor...
    );

%----- instance variables -----
color_ = initColor;
drawer_ = BackgroundDrawer();

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

    function d = drawer
        %The Drawer interface
        %FIXME: members to expose interface might not be as good as duck
        %typing.
        d = drawer_;
    end

%----- inner class -----
    function this = BackgroundDrawer
        %The implementation of the drawer interface for background.
        %FIXME: since this is just the same as filledRect, perhaps I should
        %think about a delegation/inheritance mechanism.
        %
        %Though strictly FilledRect and Background are neither a subtype of
        %the other. That's a problem with mutable objects.
        
        this = public(...
            @prepare...
            ,@release...
            ,@setVisible...
            ,@draw...
            ,@bounds...
            ,@id...
        );

        visible_ = 0;
        id_ = serialnumber();

        function prepare(window, calibration)
            %no textures to prepare for a rectangle
        end
        
        function release
        end

        function setVisible(v) 
            %FIXME: it sure would be nice if the interface
            %implementation would warn me it i'm not compatible
            %with the interface.
            visible_ = v;
        end

        function v = visible
            v = visible_;
        end

        function draw(window)
            if visible_
                Screen('FillRect', window, color_);
            end
        end
        
        function b = bounds
            b = rect_
        end

        function i = id
            i = id_;
        end
    end

end