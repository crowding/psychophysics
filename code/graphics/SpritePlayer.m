function this = SpritePlayer(patch_, process_, log_)
% function this = SpritePlayer(patch_, process_, log_)
%
% Working from a Patch and a location process, displays many concurrent,
% overlapping copies of the movie shown in the Patch. The sprite is based
% on the same set of frames, so it is played at the closest frame and pixel
% location to that requested. The location will be logged using the log
% function given.
%
% A Location Process has a single method [coords] = process_.next().
% This method gives [x y t angle alpha] coordinates of the next appearance
% of the sprite. Each successive call to next() gives another appearance of
% the sprite -- the time coordinate must be non decreasing.
% 
% log_ gives a logging function. Each time (nominal, based on input, and
% actual, based on the pixel and time grid) is counted.

this = final(...
        @init, @update, @draw, ...
        @bounds, @getVisible, @setVisible, @finishTime);

queue_ = {}; %a linked list of the sprite instances that are presently being shown

visible_ = 0;
prepared_ = 0;

toPixels_ = [];

refreshCount_ = 1; %which refresh we are about to do.
stimOnset_ = 0; %the time at which setVisible_ was called
onset_ = 0; %the time to show the first frame
            %(if displaying a sprite on refresh t=0)
interval_ = 0; %the frame interval

addtex_ = []; % the openGL texture names
subtex_ = []; % the openGL texture names
n_frames_ = 0;
from_coords_ = [];
to_coords_ = [];

%How many sprites will we anticipate at one time? This can be a
%surprisingly large number.
max_sprites_ = 16384;

texvertices_ = zeros(8, max_sprites_); %the texture vertices
screenvertices_ = zeros(8, max_sprites_); %the screen vertices
refreshes_ = zeros(1, max_sprites_); %which refresh we are on
colors_ = ones(16, max_sprites_); %the colors
indices_ = 1:max_sprites_; %Matlab indices into the circular buffer
head_ = 1; %the head, or where the next will be placed (matlab index, not C)
tail_ = 1; %the tail, or where the next will be removed (matlab index, not C)

rect_ = [];
n_ = 0; %running count of how may sprites are "in play"

    function [releaser, params] =  init(params)
        %Prepares the sprite frames.
        %
        %drawing: the Drawing object that manages the display.

        if prepared_
            error('Drawer:alreadyPrepared', ...
                'Attempted to prepare an already-prepared graphics object.');
        end
        
        toPixels_ = transformToPixels(params.cal);
        interval_ = params.cal.interval;

        %the textures...
        [addtex_, subtex_ from_coords_, to_coords_, onset_] = ...
            gl_textures(patch_, params.window, params.cal);
        
        n_frames_ = size(from_coords_, 2);
        
        rect_ = params.rect;
        
        head_ = max_sprites_; %the head, a matlab index to where the newest is.
        tail_ = max_sprites_; %the tail, a matlab index to where the oldest was.
        
        %this expression selects all indices which are 'in play'
        % xor(xor(indices_ <= head_, indices_ <= tail_), head < tail);
        
        prepared_ = 1;

        releaser = @release;
        function release()
            %Deallocates all textures, etc. associated with the prepared
            %movie.

            visible_ = 0;

            toPixels_ = [];
            interval_ = 0;
            n_ = 0;
            addtex_ = 0;
            subtex_ = 0;

            head_ = 1;
            tail_ = 1;

            %unallocate the textures
            if any(Screen('Windows') == params.window)
                require(screenGL(params.window), @() glDeleteTextures(2, [addtex_ subtex_]));
            end

            prepared_ = 0;
        end

    end

    function update
        refreshCount_ = refreshCount_ + 1;
    end

    function points = rotate(points, angle)
        siz = size(points);
        points = reshape(points, 2, numel(points)/2);
        angle = angle * pi / 180;
        points = [cos(angle) sin(angle); -sin(angle) cos(angle)] * points;
        points = reshape(points, siz);
    end

    function draw(window, next)
        global GL;
        
        latestShown = refreshCount_;
        earliestShown = refreshCount_ - n_frames_ + 1;
        
        %advance the tail of the queue:
        t2 = mod (tail_, max_sprites_) + 1;
        while (tail_ ~= head_) && (refreshes_(t2) < earliestShown)
            tail_ = t2;
            t2 = mod (tail_, max_sprites_) + 1;
        end
        
        %advance the head of the queue:
        while refreshes_(head_) <= latestShown || head_ == tail_
            h2 = mod(head_, max_sprites_) + 1;
            if h2 == tail_
                break;
            end
            head_ = h2;
            
            %TODO I need to deal with clock skew on this one, and use the
            %next() operation.
            [x, y, t, a, color] = process_.next();
            
            if isnan(t)
                break;
            end
            
            %convert coords to screen location (discretize? or no bother?)
            screenvertices_(:,head_) = toPixels_(rotate(to_coords_, a) + repmat([x;y], 4, 1));
            refreshes_(head_) = round((t + onset_) / interval_);
            color(4) = color(4) / 2;
            colors_(:,head_) = repmat(color, 4, 1);

            %TODO log the scheduled, (& discretized) stimulus onset here
        end
        
        %select the slots that will be played
        in_play = xor(xor(indices_ <= head_, indices_ <= tail_), head_ < tail_) ...
                & refreshes_ <= latestShown;
            
        %look up the texture coordinates to use
        texvertices_(:,in_play) = from_coords_(:, refreshCount_ + 1 - refreshes_(in_play));        
        
        which_play = uint32(find(repmat(in_play, 4, 1)) - 1);
        
        require(screenGL(window), @doDraw);
        function params = doDraw(params)
            %set up the drawing context.
            %can most of these be done just once? Is PTB smart enough to
            %save our context?
            glDisable(GL.DEPTH_TEST);
            glMatrixMode(GL.PROJECTION);
            glLoadIdentity;
            glOrtho(rect_(1), rect_(3), rect_(4), rect_(2), -10, 10);
            glEnable(GL.TEXTURE_2D);
            glEnable(GL.BLEND);

            %The real work of drawing begins here.
            
            %use the same blend function both times
            glBlendFunc(GL.SRC_ALPHA, GL.ONE);

            %set up our vertex arrays
            glEnableClientState(GL.TEXTURE_COORD_ARRAY);
            glEnableClientState(GL.VERTEX_ARRAY);
            glEnableClientState(GL.COLOR_ARRAY);
            
            glTexCoordPointer( 2, GL.DOUBLE, 0, texvertices_ );
            glVertexPointer( 2, GL.DOUBLE, 0, screenvertices_ );
            glColorPointer( 4, GL.DOUBLE, 0, colors_);

            %draw first the added textures, then the subtracted
            glBindTexture(GL.TEXTURE_2D,addtex_);
            glBlendEquation(GL.FUNC_ADD);
            %glDrawArrays( GL.QUADS, 0, n*4 );
            glDrawElements(GL.QUADS, length(which_play), GL.UNSIGNED_INT, which_play);
            
            glBindTexture(GL.TEXTURE_2D,subtex_);
            glBlendEquation(GL.FUNC_REVERSE_SUBTRACT);
            glDrawElements(GL.QUADS, length(which_play), GL.UNSIGNED_INT, which_play);
            %glDrawArrays( GL.QUADS, 0, n*4 );
        end
    end

    function b = bounds
        %TODO: give something meaningful?
        b = [-1 -1 1 1];
    end

    function v = getVisible();
        v = visible_;
    end

    function stimOnset = setVisible(v, next)
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
                stimOnset_ = next;
                stimOnset = next;
            end
        end
    end
end
