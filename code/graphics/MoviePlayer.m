function this = MoviePlayer(patch_)

%Interface between my old-style graphics objects and the new object system.
%Note that the stimulus onset will be keyed to the visible() command and
%not to the time onset that the Patch object specifies.
%
%Will count off frames without having to draw each one.

[this, Drawer_] = inherit(...
    Drawer()...
    ,public(@prepare, @release, @update, @draw, @bounds, @visible, @setVisible)...
    );

textures_ = [];
frameIndex_ = 1;
prepared_ = 0;
visible_ = 0;

    function prepare(drawing)
        Drawer_.prepare(drawing); %think about a mechanism for chained methods?
        try
            if prepared_
                error('Drawer:alreadyPrepared', 'Attempted to prepare an already-prepared graphics object.');
            end
            prepared_ = 1;
            textures_ = texture_movie(patch_, drawing.window(), drawing.calibration());
        catch
            err = lasterror;
            %maybe I need an idiom for the chained initialization pattern too...
            Drawer_.release();
            rethrow(err);
        end
    end

    function release()
        %following does not work because of a bug in matlab where anonymous
        %functions are not bound to separate instances of anonymous function
        %workspaces.
        %
        %totry = arrayfun(@(t)@() Screen('Close', t.texture), textures_,...
        %    'UniformOutput', 0);
        %
        %we do this instead:
        %
        totry = {};
        for t = textures_
            totry{end+1} = @() Screen('Close', t.texture);
        end

        %mark us unprepared
        totry{end+1} = @cldrawing;
        function cldrawing
            prepared_ = 0;
            visible_ = 0;
            frameIndex_ = 1;
        end
        
        %finally release the parent
        totry{end+1} = Drawer_.release; %mechanism for chained mathods?
        
        tryAll(totry{:});
    end

    function update
        if visible_
            frameIndex_ = frameIndex_ + 1;
            if frameIndex_ > numel(textures_)
                frameIndex_ = 1;
                this.setVisible(0);
            end
        end
    end

    function draw(window)
        if visible_
            t = textures_(frameIndex_);
            Screen('DrawTexture', window, t.texture, [], t.playrect);
        end
    end

    function b = bounds
        b = this.toDegrees(textures_(frameIndex_).playrect);
    end

    function v = visible();
        v = visible_;
    end

    function v = setVisible(v)
        visible_ = v;
        if (v)
            frameIndex_ = 1; %start at the beginning when shown
            %(update is called right after draw; first frame shown
            %should be 1)
        end
    end
end