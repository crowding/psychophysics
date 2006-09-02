function this = Drawing(varargin)
%Drawing holds on to graphics drawing objects and tells them when to draw
%themselves to the screen. The initialization struct should contain at
%least a 'window' field, and anything else required to draw the objects to
%the screen.
%
%

% ----- public interface -----
this = public(@add, @initializer);

% ----- instance variables -----

%the list of graphics components, restricted to the interface we use
components_ = struct('draw', {}, 'update', {}, 'init', {});
params_ = namedargs(varargin{:});

%whether we are online
online_ = 0;

% ----- methods -----
    function add(drawer)
        %Add a graphics object to the display. The object must support the 
        %'draw', 'update', and 'init' methods. Objects cannot be added
        %while the main loop is running for performance reasons.
        %
        %Aee also Drawer.
        if online_
            error('mainLoop:modificationWhileRunning',...
                ['adding graphics objects while in the display'...
                 'is not supported.']);
        end

        components_(end+1) = interface(components_, drawer);
    end

    function init = initializer(varargin)
        %Produces an initializer to be called as we enter the main loop.
        %
        %The initializer prepares all the graphics objects and outputs two
        %fields, 'drawers' and 'updaters' containing cell arrays of the
        %object's draw and update methods. On completion, the graphics
        %objects are released.
        %
        %See also require.
        
        init = JoinResource(currynamedargs(@online, varargin{:}), components_.init);
        
        function [release, params] = online(params)
            online_ = 1;
            params.draw = @draw; %to be de-abstracted upon combining with mainLoop
            params.update = @update; %to be de-abstracted upon combining with mainLoop
            
            release = @offline;
            function offline
                online_ = 0;
            end
            
            function draw(window) %to be de-functionhandled by combining with mainloop
                for i = components_
                    i.draw(window);
                end
            end
            
            function update
                for i = components_
                    i.update();
                end
            end
        end
    end
end
