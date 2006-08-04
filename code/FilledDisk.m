function this = FilledRect(x, y, size, initColor)

%A filled rectangle object that is part of displays.

%----- public interface -----
this = public(...
     @drawer... %the drawer interface
    ,@loc...
    ,@setLoc... %the rectangle interface
    ,@color...
    ,@setColor...
    );

%----- instance variables -----
[x_, y_] = deal(x, y);
color_ = initColor;
drawer_ = DiskDrawer();

%----- methods -----

%FIXME: this simple kind of accessor creation is why public() needs to
%make a class supporting subsref() and subsasgn() and provide public
%properties - a 'properties'
%struct-generating function as the argument to public() would do the trick
%for a calling convention.
%Inheritance/mixins wouldn't hurt either.

    function r = rect
        r = rect_;
    end

    function setRect(newrect)
        rect_ = newrect
    end

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
    function this = DiskDrawer
        %The implementation of the drawer interface for FilledRect.
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
            %nothing to release
        end
        
        function setVisible(v)
            visible_ = v;
        end
        
        function v = visible
            v = visible_;
        end
        
        function draw(window)
            if visible_
                Screen('FillRect', window, color_, rect_);
            end
        end

        function b = bounds
            b = rect_;
        end
        
        function i = id
            i = id_;
        end
    end
end