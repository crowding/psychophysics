function this = SpritePlayer(patch_, process_, log_)
% function this = SpritePlayer(patch_, process_, log_)
% 
% % 4556 9.132 s 3.466 s %before removing extraneous save/restore
% % 6840 6.591 s 3.943 s %after removal, woot!
% % 15324 14.937 s 9.094 %after adding rotation.
% % 3064 824.031 s 18.187 s %without the rotation
%
% Working from a Patch and a location process, displays many concurrent,
% overlapping copies of the movie shown in the Patch. the sprite is based
% on the same set of frames, so it is played at the closest frame and pixel
% location to that requested. The location will be logged using hte log
% function given.
%
% A Location Process has a single method [coords] = process_.next().
% This method gives [x y t] coordinates of the next appearance of the
% sprite. Each successive call to next() gives another appearance of the
% sprite -- the time coordinate must be non decreasing.
% 
% log_ gives a logging function. Each time (nominal, based on input, and
% actual, based on the pixel and time grid) is counted.

%constants
GL_BLEND_EQUATION = hex2dec('8009');
GL_BLEND_DST = hex2dec('0BE0');
GL_BLEND_SRC = hex2dec('0BE1');

this = final(...
        @init, @update, @draw, ...
        @bounds, @getVisible, @setVisible, @finishTime);

queue_ = {}; %a linked list of the sprite instances that are presently being shown

visible_ = 0;
prepared_ = 0;

toDegrees_ = [];
toPixels_ = [];

refreshCount_ = 1; %which refresh we are about to do.
onset_ = 0; %the time at which setVisible_ was called
interval_ = 0; %the frame interval

textures_ = []; %the array of textures is shared across alol Sprite invocations
frameOnset_ = NaN; %the time of the first refresh where this is visible
frameIndex_ = []; %index into this aray with the refresh number
frameCounts_ = []; %index into this array with the refresh number

    function [releaser, params] =  init(params)
        %Prepares the sprite frames.
        %
        %drawing: the Drawing object that manages the display.

        if prepared_
            error('Drawer:alreadyPrepared', ...
                'Attempted to prepare an already-prepared graphics object.');
        end
        toDegrees_ = transformToDegrees(params.cal);
        toPixels_ = transformToPixels(params.cal);
        interval_ = params.cal.interval;

        %the textures may have one, zero, or many frames per index. On
        %each refresh we need to know which frames to show...
        textures_ = texture_movie(patch_, params.window, params.cal);
        [refreshes, i] = sort([textures_.frame]);
        textures_ = textures_(i);

        frame_changes = [1, find(diff(refreshes)) + 1];
        texture_counts = [diff(frame_changes), numel(textures_) - frame_changes(end) + 1];
        first_frame = refreshes(1);
        frameIndex_ = zeros(1, refreshes(end) - refreshes(1) + 1);
        frameCounts_ = zeros(size(frameIndex_));

        frameIndex_(refreshes(frame_changes)) = frame_changes;
        frameCounts_(refreshes(frame_changes)) = texture_counts;

        prepared_ = 1;

        releaser = @release;
        function release()
            %Deallocates all textures, etc. associated with the prepared movie.

            %use tryAll to clean up each texture, continuing on errors
            %encountered.
            totry = {};
            for t = textures_(:)'
                totry{end+1} = @()closer(t.texture);
            end

            function closer(tex)
                if any(Screen('Windows') == params.window)
                    Screen('Close', tex);
                end
            end

            %mark us unprepared
            totry{end+1} = @cldrawing;
            function cldrawing
                prepared_ = 0;
                visible_ = 0;
                queue_ = {};
                
                toDegrees_ = [];
                toPixels_ = [];
                interval_ = 0;
                
                frameOnset_ = 0;
                frameIndex_ = [];
                frameCounts = [];
            end

            tryAll(totry{:});
        end

    end

    function update
        refreshCount_ = refreshCount_ + 1;
    end

    function draw(window, next)
        %move through the linked list of sprites.
        nqueue = {};
        queue = queue_;
        maxRefreshOnset = -Inf;
        while(numel(queue) > 1)
            [refreshOnset xPos yPos angle queue] = queue{:};
            maxRefreshOnset = max(maxRefreshOnset, refreshOnset);
            
            ref = refreshCount_ - refreshOnset + 1;

            if ref >= 1 && ref <= numel(frameIndex_)
                %draw the textures
                for t = textures_(frameIndex_(ref):frameIndex_(ref)+frameCounts_(ref) - 1)

                    Screen('DrawTexture', window, t.texture, [], t.playrect + [xPos yPos xPos yPos] ...
                        , angle, [], [], t.sourceFactor, t.destFactor, t.blendEquation);
                end
            elseif ref > numel(frameIndex_)
                continue;
            end

            nqueue = {refreshOnset xPos yPos angle nqueue};
        end
        
        %If the maxOnset is too small in relation to the window, request a
        %new sprite (repeat as necessary)
        while maxRefreshOnset - refreshCount_ < 1
            [x, y, t, a] = process_.next();
            if isnan(t)
                break;
            end
            
            %convert coords
            [x, y] = toPixels_(x, y);
            [cx, cy] = toPixels_(0, 0);
            x = round(x-cx);
            y = round(y-cy);
            refresh = round((t + textures_(1).time) / interval_);
            
            maxRefreshOnset = max(refresh, maxRefreshOnset);
            
            %TODO log the scheduled, (& discretized) stimulus onset here

            nqueue = {refresh x y a nqueue};
        end
        
        queue_ = nqueue;
    end

    function b = bounds
        %TODO: give something meaningful?
        b = [-1 -1 1 1];
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
            refreshCount_ = 1;
            
            if exist('next', 'var');
                onset_ = next;
                onset = next;
            end
        end
    end
end
