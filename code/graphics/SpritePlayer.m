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

toDegrees_ = [];
toPixels_ = [];

refreshCount_ = 1; %which refresh we are about to do.
stimOnset_ = 0; %the time at which setVisible_ was called
onset_ = 0; %the time at which the setVisible_ was called
interval_ = 0; %the frame interval

addtex_ = []; % the openGL texture names
subtex_ = []; % the openGL texture names
n_frames_ = 0;
from_coords_ = [];
to_coords_ = [];

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

        prepared_ = 1;

        releaser = @release;
        function release()
            %Deallocates all textures, etc. associated with the prepared
            %movie.

            totry = {};

            %unallocate the textures
            totry{end+1} = @releaseTextures;
            function releaseTextures()
                if any(Screen('Windows') == params.window)
                    require(screenGL(params.window), @() glDeleteTextures(2, [addtex_ subtex_]));
                end
            end
            
            %mark us unprepared
            totry{end+1} = @cldrawing;
            function cldrawing %UPDATE THESE VARIABLES
                prepared_ = 0;
                visible_ = 0;
                queue_ = {};
                
                toPixels_ = [];
                interval_ = 0;
                n_ = 0;
                addtex_ = 0;
                subtex_ = 0;
            end

            tryAll(totry{:});
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
        %move through the linked list of sprites.
        global GL;
        nqueue = {};
        queue = queue_;
        maxRefreshOnset = -Inf;
        
        %we will collect all the coordinates etc into these arrays:
        texvertices = zeros(8, n_); %8 coordinates per quad
        screenvertices = zeros(8, n_);
        colors = ones(16, n_);
        n = 0; %how many we are drawing this refresh

        %'queue' is a linked list of textures 'in play.' Each element of
        %queue is {refreshOnset, screenCoords, queue'} where queue' is
        %the rest of the queue. (this nested cell array is a relatively
        %fast pure-matlab way to have a list whose size is constantly
        %changing. Only drawback is that iterating thorugh it reverses it.)
        
        while(numel(queue) > 1)
            [refreshOnset screenCoords alpha queue] = queue{:};
            maxRefreshOnset = max(maxRefreshOnset, refreshOnset);
            
            ref = refreshCount_ - refreshOnset + 1; % which refresh of THIS TEXTURE are we on?

            if ref >= 1 && ref <= n_frames_
                n = n + 1; %here's a sprite we will show
                
                %fill in the texture array
                texvertices(:,n) = from_coords_(:,ref);
                screenvertices(:,n) = screenCoords;
                colors([4 8 12 16],n) = alpha/2;
            end
            
            if ref >= n_frames_
                %we've run out of frames on this sprite; drop it from the
                %queue
                n_ = n_ - 1;
            else
                nqueue = {refreshOnset screenCoords alpha nqueue};
            end
        end
        
        %draw the vertex arrays to the screen.
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
            glColor4f(1, 1, 1, 0.1);

            %The real work of drawing begins here.
            
            %use the same blend function both times
            glBlendFunc(GL.SRC_ALPHA, GL.ONE);

            %set up our vertex arrays
            glEnableClientState(GL.TEXTURE_COORD_ARRAY);
            glEnableClientState(GL.VERTEX_ARRAY);
            glEnableClientState(GL.COLOR_ARRAY);
            
            glTexCoordPointer( 2, GL.DOUBLE, 0, texvertices );
            glVertexPointer( 2, GL.DOUBLE, 0, screenvertices );
            glColorPointer( 4, GL.DOUBLE, 0, colors);

            %draw first the added textures, then the subtracted
            glBindTexture(GL.TEXTURE_2D,addtex_);
            glBlendEquation(GL.FUNC_ADD);
            glDrawArrays( GL.QUADS, 0, n*4 );

            glBindTexture(GL.TEXTURE_2D,subtex_);
            glBlendEquation(GL.FUNC_REVERSE_SUBTRACT);
            glDrawArrays( GL.QUADS, 0, n*4 );
        end
        
        %If the maxOnset is too small in relation to the window, request a
        %new sprite (repeat as necessary)
        while maxRefreshOnset - refreshCount_ < 1
            %TODO I need to deal with clock skew on this one, and use the
            %next() operation.
            [x, y, t, a, alpha] = process_.next();
            if isnan(t)
                break;
            end
            
            %convert coords to screen location
            screenCoords = toPixels_(rotate(to_coords_, a) + repmat([x;y], 4, 1));
            refresh = round((t + onset_) / interval_);
            maxRefreshOnset = max(refresh, maxRefreshOnset);
            
            %TODO log the scheduled, (& discretized) stimulus onset here
            nqueue = {refresh screenCoords alpha nqueue};
            n_ = n_ + 1;
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
