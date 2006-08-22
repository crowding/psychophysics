function this = Drawing(details_)
%Drawing is a holder for graphics drawing objects.
%Drawing tries to coordinate the allocation of resources (textures etc.)
%for graphics objects; therefore it needs to have cleanup code. Therefore
%this does not return the Drawing object itself, but an initializer you can
%use with REQUIRE.

% ----- public interface -----
this = inherit(...
    public(@add, @remove, @clear, @update, @draw, @calibration, @window));
% ----- instance variables -----

components_ = cell(0);

% ----- methods -----
    function add(drawer)
        %add a single component to the drawing and prepare it to be drawn.
        drawer.prepare(this); %do this first, since it
                              %could error
        components_{end+1} = drawer;
    end

    function remove(drawer)
        %remove and release a single component from the drawing.
        id = drawer.id();
        
        found = find(cellfun(@(x) x.id() == id, drawer));
        if ~isempty(found)
            removeAt(found(1));
        end
    end

    function clear
        %clear all the components from the graphics
        errs = emptyOf(lasterror);
                
        for ii = numel(components_):-1:1 %stepping backwards
            %try to clear everything, postponing errors for later
            try
                removeAt(ii);
            catch
                errs(end+1) = lasterror;
            end
        end
        if ~isempty(errs)
            rethrow(errs(1)); %FIXME: way to throw multiple errors?
        end
    end

%look at SpaceEvents.update(), which looks like this, but runs much faster
%than this did! What's going on?
%{
    function update
        for com = components_
            com{:}.update(); %updates for each element
        end
    end
%}

    updater_ = @(X) X.update();
    function update
        cellfun(updater_, components_);
    end

    function c = calibration()
        c = details_.cal;
    end

    function w = window()
        w = details_.window;
    end

%why is this so much faster than update() when they are the same function and draw() does more in its subfunctions?!?
    drawer_ = @(X) X.draw(details_.window);
    function draw
        cellfun(drawer_, components_);
    end

%----- internal functions -----

    function removeAt(index)
        %private function.
        %remove a component, THEN deallocates it
        it = components_{index};
        components_{index} = {};
        it.release();
        
        %hooray for my closure-reference objects --
        %this order of operations be impossible with matlab's dumb
        %copy-on-write objects, and there'd be many more than 3 lines:
        %
        %try
        %   components_(found(index)) = release(components_(found(index)));
        %catch
        %   err = lasterror;
        %   components_(found(index)) = [];
        %   rethrow(err);
        %end
        %components_(found(index)) = [];
    end
end