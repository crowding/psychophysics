function this = Drawing(window_, calibration_)
%Drawing is a holder for graphics drawing objects.
%Drawing tries to coordinate the allocation of resources (textures etc.)
%for graphics objects; therefore it needs to have cleanup code. Therefore
%this does not return the Drawing object itself, but an initializer you can
%use with REQUIRE.

% ----- public interface -----
this = public(@add, @remove, @clear, @draw);
% ----- instance variables -----

components_ = cell(0);

% ----- methods -----
    function add(drawer)
        %add a single component to the drawing and prepare it to be drawn.
        drawer.prepare(window_, calibration_); %do this first, since it
                                               %could error
        components_{end+1} = drawer;
    end

    function remove(drawer)
        %remove and release a single component from the drawing.
        id = drawer.id();
        errors = emptyOf(lasterror);
        
        found = find(cellfun(@(x) x.id() == id, drawer));
        if ~isempty(found)
            removeAt(found(1));
        end
    end

    function clear
        %clear all the components from the graphics
        errs = emptyOf(lasterror);
                
        for i = numel(components_):-1:1 %stepping backwards
            %try to clear everything, postponing errors for later
            try
                removeAt(i);
            catch
                errs(end+1) = lasterror;
            end
        end
        if ~isempty(errs)
            rethrow(errs(1)); %FIXME: way to throw multiple errors?
        end
    end

    function draw
        %draw all the objects on the screen.
        cellfun(@(x)x.draw(window_), components_);
    end
    
    function removeAt(index)
        %private function.
        %remove a component, THEN deallocates it
        it = components_{index};
        components_{index} = {};
        it.release();
        
        %hooray for my closure-reference objects --
        %this order of operations be impossible with matlab's dumb
        %copy-on-write objects, and there'd be many more than 2 lines:
        %
        %try
        %   components_(found(1)).release();
        %catch
        %   err = lasterror;
        %   components_(found(i)) = [];
        %   rethrow(err);
        %end
        %components_(found(1)) = [];
    end
end