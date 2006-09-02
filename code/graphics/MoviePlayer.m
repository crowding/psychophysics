function this = MoviePlayer(patch_)

%Interface between my old-style graphics objects and the new object system.
%Note that the stimulus onset will be keyed to the visible() command and
%not to the time onset that the Patch object specifies.
%
%Will count off frames without having to draw each one.

[this, Drawer_] = inherit(...
    Drawer()...
    ,public(...
        @prepare, @release, @update, @draw, ...
        @bounds, @getVisible, @setVisible, @finishTime)...
    );

textures_ = [];
frameIndex_ = 1; %whcih frame we are about to show
frameCounter_ = 1; %the index into the teture array (may be different from frame index
visible_ = 0;
prepared_ = 0;
toDegrees_ = [];

    function prepare(params)
        %Prepares the movie for drawing into a window.
        %
        %drawing: the Drawing object that manages the display.
        
        Drawer_.prepare(drawing); %think about a mechanism for chained methods?
        try
            if prepared_
                error('Drawer:alreadyPrepared', ...
                    'Attempted to prepare an already-prepared graphics object.');
            end
            prepared_ = 1;
            textures_ = texture_movie(patch_, params.window, params.cal);
            toDegrees_ = transformToDegrees(params.cal);
        catch
            err = lasterror;
            %maybe I need an idiom for the chained initialization pattern too...
            Drawer_.release();
            rethrow(err);
        end
    end

    function release()
        %Deallocates all textures, etc. associated with the prepared movie.
        
        %we have a bunch of things to clean up, and should keep trying if
        %any one fails. Thus we place each cleanup item into a function
        %handle and pass the whole mess to tryAll.
        
        %following does not work because of a bug in matlab where anonymous
        %functions are not bound to separate instances of anonymous function
        %workspaces.
        %
        %totry = arrayfun(@(t)@() Screen('Close', t.texture), textures_,...
        %    'UniformOutput', 0);
        %
        %we have to do this instead:
        totry = {};
        for t = textures_'
            totry{end+1} = @() Screen('Close', t.texture);
        end

        %mark us unprepared
        totry{end+1} = @cldrawing;
        function cldrawing
            prepared_ = 0;
            visible_ = 0;
            frameIndex_ = 1;
            frameCounter = 1;
        end
        
        %finally release the parent
        totry{end+1} = Drawer_.release; %mechanism for chained mathods?
        
        tryAll(totry{:});
    end

    function update
        %advance 1 frame forward in the movie. Should be called by a main
        %loop which is responsible for keeping track of whether drawing is
        %occurring on schedule, and giving extra update() calls if frames
        %are skipped.
        
        if visible_
            frameCounter_ = frameCounter_ + 1;
            if textures_(frameIndex_).frame < frameCounter_
                frameIndex_ = frameIndex_ + 1;
            end
            if frameIndex_ > numel(textures_)
                %stop on last frame for best cooperation with bounds()
                frameIndex_ = frameIndex_ - 1;
                setVisible(0);
            end
        end
    end

    function draw(window)
        if visible_
            t = textures_(frameIndex_);
            if (t.frame == frameCounter_)
                Screen('DrawTexture', window, t.texture, [], t.playrect);
            end
        end
    end

    function b = bounds
        %Gives the current bounds of the object, i.e. the bounds of
        %the next frame to be shown.
            b = toDegrees_(textures_(frameIndex_).playrect);
    end

    function v = getVisible();
        v = visible_;
    end

    function onset = setVisible(v, next)
        % v:     if true, will start drawing the movie at the next refresh.
        %
        % next:  if exists and set to the scheduled next refresh, gives the
        %        stimulus onset time (which may be different from the next
        %        refresh for many movies)
        % ---
        % onset: the stimulus onset time.
        visible_ = v;
        
        if v
            %start at the first frame
            %(update is called right after draw; first frame shown
            %should be the first frame)
            frameIndex_ = 1;
            frameCounter_ = textures_(1).frame;
            
            if exist('next', 'var');
                onset = next - textures_(1).time;
            end
        end
    end

    function finish = finishTime
        %returns the time (relative to stimulus onset) that the stimulus
        %will show its last frame.)
        finish = textures_(end).time;
    end
end
