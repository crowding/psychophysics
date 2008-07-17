function this = SpritePlayer(varargin)
% function this = SpritePlayer(patch, process, log)
%
% Working from a Patch and a location process, displays many concurrent,
% overlapping copies of the movie shown in the Patch. The sprite is based
% on the same set of frames, so it is played at the closest frame and pixel
% location to that requested. The location will be logged using the log
% function given.
%
% A Location Process has a single method [coords] = process.next().
% This method gives [x y t angle alpha] coordinates of the next appearance
% of the sprite. Each successive call to next() gives another appearance of
% the sprite -- the time coordinate must be non decreasing.
% 
% log gives a logging function. Each time (nominal, based on input, and
% actual, based on the pixel and time grid) is counted. TODO: this is not
% written...

patch = [];
process = [];
log = [];
visible = 0; % a misnomer: setting visible means "start playing"
drawn = 1; %by default, is drawn.

varargin = assignments(varargin, 'patch', 'process', 'log');

persistent init__; %#ok
this = autoobject(varargin{:});

prepared_ = 0;
toPixels_ = [];
refreshCount_ = 0;  %which refresh we are about to do.
onset_ = 0;         %the time to show the first frame
                    %(if displaying a sprite on refresh t=0)
interval_ = 0;      %the frame interval

addtex_ = []; % the openGL texture names
subtex_ = []; % the openGL texture names
n_frames_ = 0;
from_coords_ = [];
to_coords_ = [];

%How many sprites will we anticipate at one time? This can be a
%surprisingly large number.
max_sprites_ = 4096;

texvertices_ = zeros(8, max_sprites_); %the texture vertices
screenvertices_ = zeros(8, max_sprites_); %the screen vertices
refreshes_ = zeros(1, max_sprites_); %which refresh we are on

colors_ = zeros(12, max_sprites_) + 0.5; %the colors
%colors_([4 8 12], :) = 1;

head_ = max_sprites_; %matlab index to where the newest IS.
tail_ = max_sprites_; %matlab index to where the oldest WAS.

    function [releaser, params, next] = init(params)
        %Renders the sprite frames; prepares for drawing.
        %
        %drawing: the Drawing object that manages the display.

        if prepared_
            error('Drawer:alreadyPrepared', ...
                'Attempted to prepare an already-prepared graphics object.');
        end
        
        i = joinResource(@initTextures, @initglparams);
        [releaser, params, next] = i(params);
        
        function [release, params] = initTextures(params)
            toPixels_ = transformToPixels(params.cal);
            interval_ = params.cal.interval;

            head_ = max_sprites_;
            tail_ = max_sprites_;

            %the textures...
            [addtex_, subtex_ from_coords_, to_coords_, onset_] = ...
                gl_textures(patch, params.window, params.cal);

            n_frames_ = size(from_coords_, 2);

            process.reset();

            prepared_ = 1;
            
            advanceQueue(); %preload for the stimulus onset

            release = @r;

            function r()
                %unallocate the textures
                if any(Screen('Windows') == params.window)
                    %FIXME: using require() in the midst of a release
                    %during a resource panic...
                    %require(screenGL(params.window), @() glDeleteTextures(2, [addtex_ subtex_]));
                    try
                        Screen('BeginOpenGL', params.window);
                    catch
                    end
                    try
                        glDeleteTextures(2, [addtex_ subtex_]);
                    catch
                        Screen('EndOpenGL', params.window);
                        rethrow(lasterror);
                    end
                    Screen('EndOpenGL', params.window);
                else
                    %try it anyway?
                    glDeleteTextures(2, [addtex_ subtex_]);
                end
                %Deallocates all textures, etc. associated with the prepared
                %movie.

                visible = 0;
                prepared_ = 0;

                toPixels_ = [];
                interval_ = 0;
                addtex_ = 0;
                subtex_ = 0;

            end
        end
        
        function [release, params] = initglparams(params) %#ok
            global GL;
            require(screenGL(params.window), @doInitParams);
            
            function doInitParams
                glDisable(GL.DEPTH_TEST);
                glMatrixMode(GL.PROJECTION);
                glLoadIdentity;
                
                %load in the translation from "degrees" in the calibration
                %function...
                glOrtho(params.rect(1), params.rect(3), params.rect(4), params.rect(2), -10, 10);
                glEnable(GL.TEXTURE_2D);
%                glEnable(GL.BLEND);

                %use the same blend function both times
%                glBlendFunc(GL.SRC_ALPHA, GL.ONE);

                %set up vertex array state
                glEnableClientState(GL.TEXTURE_COORD_ARRAY);
                glEnableClientState(GL.VERTEX_ARRAY);
                glEnableClientState(GL.COLOR_ARRAY);

                release = @r;
            end

            function r()
                %do nothing
            end
        end



    end

    function update(frames)
        if visible
            refreshCount_ = refreshCount_ + frames;
        end
    end

    function points = rotate(points, angle)
        siz = size(points);
        points = reshape(points, 2, numel(points)/2);
        angle = angle * pi / 180;
        rot = sin([pi/2-angle, angle; -angle, pi/2-angle]);
        points = rot * points;
        points = reshape(points, siz);
    end

    function advanceQueue()
        %{
        if head_ > tail_
            l1 = tail_ + 1; r1 = head_ - 1;
            l2 = 1; r2 = 0;
        else
            l1 = tail_ + 1; r1 = max_sprites_;
            l2 = 1; r2 = head_ - 1;
        end
        %}
        
        latestShown = refreshCount_;
        earliestShown = refreshCount_ - n_frames_ + 1;
        
        %advance the tail of the queue to drop all sprites we are finished
        %with
        t2 = mod (tail_, max_sprites_) + 1;
        while (tail_ ~= head_) && (refreshes_(t2) < earliestShown)
            tail_ = t2;
            t2 = mod (tail_, max_sprites_) + 1;
        end
        
        %advance the head of the queue:
        h2 = head_;
        while refreshes_(head_) <= latestShown || head_ == tail_
            h2 = mod(head_, max_sprites_) + 1;
            if h2 == tail_
                break;
            end
            
            %NOTE: Despite the possibility of clock skew, I use the number
            %of refreshes to determine which sprite to show when, and not
            %the clock value. This is so that identical frame sequences are
            %shown for identical stimuli.

            [x, y, t, a, color] = process.next();
            
            if isnan(t)
                break;
            end

            head_ = h2;
            
            %convert coords to screen location (discretize? or no bother?)
            s = rotate(to_coords_, a);
            s = s + [x;y;x;y;x;y;x;y];
            s = toPixels_(s);
            screenvertices_(:,head_) = s;
            
            refreshes_(head_) = round((t + onset_) / interval_);
            ccolor = (color(:) * [1 1 1 1]);
            try
                colors_(:,head_) = ccolor(:);
            catch
                noop
            end

            %TODO log the scheduled, (& discretized) stimulus onset here
        end
    end

    function draw(window, next)
        % was (1938 calls, 8.300 sec) with colors
        % was (2665 calls, 11.071 sec) still with colors
        if ~visible
            return
        end

        global GL;
        
        advanceQueue(); %Works here. But shouldn't this be done afterwards
        %(since it is done once already at init() time).
        
        %visible indicator of buffer fill
        %if h2 == tail_
        %    color = [1;0;0];
        %else
        %    color = [0.5;0.5;0.5];
        %end
        
        %select the portion of the buffer that will be drawn - in two
        %intervals, one of which may be empty.
        %Note by construction the head always points to ONE TOO MANY
        %(FIXME - even when the underlying process returned NaN!)
        if head_ >= tail_
            l1 = tail_ + 1; r1 = head_ - 1;
            l2 = 1; r2 = 0;
        else
            l1 = tail_ + 1; r1 = max_sprites_;
            l2 = 1; r2 = head_ - 1;
        end

        if ~drawn
            return;
        end
        
        %look up the texture coordinates to use.
        texvertices_(:,[l1:r1 l2:r2]) = from_coords_(:, refreshCount_ + 1 - refreshes_([l1:r1 l2:r2]));

        %set up the drawing context.
        %this section was in a require(screenGL(window) but was made
        %stupid for speed
        Screen('BeginOpenGL', window);

        %draw first the added textures, then the subtracted
        glTexCoordPointer( 2, GL.DOUBLE, 0, texvertices_ );
        glVertexPointer( 2, GL.DOUBLE, 0, screenvertices_ );
        glColorPointer( 3, GL.DOUBLE, 0, colors_);
        
        glBindTexture(GL.TEXTURE_2D,addtex_);
        %glBlendEquation(GL.FUNC_ADD);
        glDrawArrays( GL.QUADS, (l1-1)*4, max((r1-l1 + 1)*4,0) );
        glDrawArrays( GL.QUADS, (l2-1)*4, max((r2-l2 + 1)*4,0) );

        glBindTexture(GL.TEXTURE_2D,subtex_);
        %glBlendEquation(GL.FUNC_REVERSE_SUBTRACT);
        glDrawArrays( GL.QUADS, (l1-1)*4, max((r1-l1 + 1)*4, 0) );
        glDrawArrays( GL.QUADS, (l2-1)*4, max((r2-l2 + 1)*4, 0) );
        glFlush();
        Screen('EndOpenGL', window);
    end

    function v = getVisible()
        v = visible;
    end

    function stimOnset = setVisible(v, next)
        % v:     if true, will start drawing the movie at the next refresh.
        %
        % next:  if exists and set to the scheduled next refresh, gives the
        %        stimulus onset time (which may be different from the next
        %        refresh for many movies)
        % ---
        % onset: the stimulus onset time.
        visible = v;
        
        if v
            %starts at the first frame -- should already be initialized to
            %do so
            %(update is called after draw; first frame shown
            %should be the first frame) -- this is checked using PixelTest.
            if nargin >= 2 %bah, 'exist' takes too long.
                stimOnset = next;
            end
        else
            %reset to show at the next appearance.
            
            head_ = max_sprites_; %matlab 1-based index to where the newest IS.
            tail_ = max_sprites_; %matlab 1-based index to where the oldest WAS.
            process.reset();
            refreshCount_ = 0;
            advanceQueue();
        end
    end

    function setDrawn(s)
        drawn = s;
    end

    function d = getDrawn()
        d = drawn;
    end

    function b = bounds()
        %ask the process for a "bounds" based on what refresh count we're
        %on. This depends on whether the motion process has a notion of
        %bounds.
        b = process.bounds(refreshCount_ * interval_);
    end

    function l = loc()
        l = process.loc(refreshCount_ * interval_);
    end
end
