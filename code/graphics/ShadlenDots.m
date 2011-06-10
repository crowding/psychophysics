function this = ShadlenDots(varargin)
    %A graphics object; draws variable-coherence random dot motion
    %according to the specifications used in the Shadlen lab.
    %
    % All calculations take place within a square aperture
    % in which the dots are shown. The dots are constructed in [buffer] sets that are
    % plotted in sequence.  For each set, the probability that a dot is
    % replotted in motion -- as opposed to randomly replaced -- is given by the
    % dotInfo.coh value.  
    %
    %PBM intends this to produce exactly the same dots as dotsX BUT THIS
    %HAS NOT BEEN TESTED!!!
    %
    % created by PBM, based on dotsX by MKMK, in turn based on ShadlenDots by MNS, JIG et al.
    
    %public properties:
    
    visible = 0; %whether it is deing drawn/updated.
    
    coh = 0.5; %ranges between 0 and 1.
    speed = 5; %degrees per second
    buffers = 3; %number of buffers.
    dir = 0; %Motion direction. right = 0, down = 90, etc.
    dotSize = 2; %in pixels.
    dotColor = [255;255;255]; %in color index.
    dotType = 0; %0 for squares, 1, for antialiased circles, 2 for high quality antialiased circles
    maxDotsPerFrame = Inf; %no sense limiting this on modern gfx hardware -- just log skipped frames is all.
    density = 16.7; %dots per square degree per second, historical shadlen value.
    aperture = 5; %dots are computed in a square aperture of this width, then masked into a circle.
    
    loc = [0;0];
    
    %We want our own private random number seed for this dots field.
    generator = UniformDistribution();
              
    persistent init__;
    this = autoobject(varargin{:});
    
    %private vars
    degreesToPixels_ = [];
    interval_ = [];
    
    global GL_; %filled out by getScreen
    
    %written in caps because the sequence and number of times you call rand
    %is critical for backwards compatibility
    RAND_ = generator.e; %having a function handle is faster than having to access a struct in a nested function.

    %defensive measure against programmer error
    rand = @(varargin)error('ShadlenDots:whoops', 'you should not be calling plain rand()!');
    
    function [release, params] = init(params)
        degreesToPixels_ = transformToPixels(params.cal);
        interval_ = params.cal.interval; %note, this is the calibrated interval, as opposed to the 
        RAND_ = generator.e;
        release = @noop;
    end

    dxdy_ = [];
    lastFrame_ = 0; %frame 1 displays buffer 1, etc.
    dots_ = []; %dot coordinates
    function setVisible(vis, status)
        if vis
            if (nargin < 2)
                error ('ShadlenDots:setVisibleNeedsStatus', 'Must set dots visible during the experiment, providing the status so I can have starting refresh number');
            end
            %N.B. the "- 1" makes it update/move the dots once before drawing
            %the first frame, which is what dotsX did
            lastFrame_ = 0; %will be updated once before drawing, just like dotsX
            
            %Given the same seed, this should generate the same initial dots. as
            %dotsX. But here X/Y are rows, individual dots are columns and
            %the third dimension is buffer index. This matches the expected
            %arguments to drawDots and transformToPixels.
            ndots = min(maxDotsPerFrame, ceil(density * aperture.^2 .* interval_));
            dots_ = permute(reshape(RAND_(ndots*buffers, 2), [ndots buffers 2]), [3 1 2]);
            
            %dxdy is the step size relative to the aperture
            %(for each dot, though they're initialized to all the same.)
            dxdy_ = repmat(speed ./ aperture .* buffers .* interval_ ...
                .* [cos(pi*dir/180.0);-sin(pi*dir/180.0)], 1, ndots);
            
            visible = 1;
        else
            visible = 0;
        end
    end

    function update(nFrames)
        if visible && nFrames >= 1
            for frame = lastFrame_+1:lastFrame_+nFrames
                %update dots.
                %note: I store my dots an an array that's transposed as
                %compared to dotsX. When generating random numbers, I need
                %to pay attention to this and take measures to preserve the
                %previous order of generation.
                bufferIndex = mod(frame, buffers) + 1;
                dotfield = dots_(:,:,bufferIndex);
                
                %1 where the dod survives and moves to the next frame
                moved = RAND_(1, size(dots_, 2)) < coh;
                
                dotfield(:,moved) = dotfield(:,moved) + dxdy_(:,moved);
                dotfield(:,~moved) = RAND_(sum(~moved),2)'; %generate then transpose, preserving random number order of dotsX.
                
                %wrap around -- check if any dots are out of the square
                %aperture.
                wrapped = any(dotfield > 1 | dotfield < 0, 1);
                Nwrapped = sum(wrapped);
                if Nwrapped > 0
                    %PBM: I don't get why (for diagonal motion) all the
                    %wrapped dots in each frame are placed on the same
                    %edge, rather than being distributed between edges,
                    %but I am preserving the effect of the existing dotsX
                    %algorithm for the sake of our precious bodily
                    %flui^H^H^H^Hrandom number seeds.
                    
                    xdir = sin(pi*dir/180.0);
                    ydir = cos(pi*dir/180.0);
                    % flip a weighted coin to see which edge to put the
                    % replaced dots
                    
                    if RAND_() < abs(xdir)/(abs(xdir) + abs(ydir))
                        %dots wrap to random locations on the left/right edge
                        dotfield(:,wrapped) = [RAND_(1, Nwrapped); (xdir > 0)*ones(1,Nwrapped)];
                    else
                        %dots wrap to random locations on the top/bottom edge
                        dotfield(:,wrapped) = [(ydir < 0)*ones(1, Nwrapped); RAND_(1, Nwrapped)];
                    end
                end
                %Store the updated dots buffer.
                dots_(:,:,bufferIndex) = dotfield;
            end
            
            lastFrame_ = frame;
        end
    end
    
    function draw(window, when, refresh)
        %the procedure for drawing the dots.
        
        if visible
            bufferIndex = mod(lastFrame_, buffers) + 1;
            dotfield = dots_(:,:,bufferIndex);
            
            %there may be some off-by-one-pixel business here between this
            %and dotsX.
            apertureRect = floor(degreesToPixels_([loc(:) - aperture/2; loc(:) + aperture/2]));
            l = loc(:);
            dotfield = degreesToPixels_(bsxfun(@minus, (dotfield .* aperture) - aperture/2, loc(:)));
            
            %The dots are actually drawn in a circular mask inside the
            %aperture.
            
            %We begin by drawing the circular mask in the alpha channel.
            [oldSrc,oldDst,oldMask] = Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO', [0 0 0 1]);
            Screen('FillRect', window, [0 0 0 0], apertureRect + [-dotSize; -dotSize; dotSize; dotSize]);
            Screen('FillOval', window, [0 0 0 255], apertureRect);

            %now draw dots using the mask. NOTE this method of masking
            %precludes us from using antialiased dots.... :(
            Screen('BlendFunction', window, 'GL_DST_ALPHA', 'GL_ONE_MINUS_DST_ALPHA', [1 1 1 1]);
            Screen('DrawDots', window, dotfield, dotSize, dotColor, [0 0], dotType);

            %clear alpha channel and restore blend factors
            Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO', [0 0 0 1]);
            Screen('FillRect', window, apertureRect + [-dotSize; -dotSize; dotSize; dotSize], [0 0 0 255]);
            Screen('BlendFunction', window, oldSrc, oldDst, oldMask);
        end
    end
end