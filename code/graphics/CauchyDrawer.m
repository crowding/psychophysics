function this = CauchyDrawer(varargin)

    AssertOpenGL;
    global GL;
    
    visible = 0;
    %the "source" is an object that determines where and how to draw each
    %cauchy blob for each frame. It has one method, get(next, refresh),
    %next being the timestamp and refresh being the refresh count. Its
    %return arguments are:
    %[x, y, angle, wavelength, order, width, color, phase]
    source = DummyCauchySource();
    
    %hte handle for the cauchy shader program.
    persistent program_;
    if (isempty(program_))
        program_ = -1;
    end
    
    %how accurately to render. Any bits of the cauchy patch that are less
    %than this amplitude are not remdered.
    accuracy = 0.001;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function setVisible(s)
        visible = s;
    end

    frameCount_ = 0;
    splitTextures_ = 0;

    function [release, params] = init(params)
        %initialize the openGL environment, shader, and texture.
        %we initialize the environment to measure in the same degrees as we
        %are calibrated to...

        AssertGLSL;

        params = require(params, screenGL(params.window), @setupOpenGL);
        function params = setupOpenGL(params)
            %figure out whether we are in a 16-bit buffer?
            if (params.screenInfo.BitsPerColorComponent > 8) && (params.screenInfo.GLSupportsBlendingUpToBpc >= params.screenInfo.BitsPerColorComponent)
                %we are running in a high-dynamic-range buffer with
                %blending, yay
                splitTextures_ = 0;
            else
                %boo
                splitTextures_ = 1;
            end

            glDisable(GL.DEPTH_TEST);
            glMatrixMode(GL.PROJECTION);

            glLoadIdentity;

            frameCount_ = 0;

            %set up a projection so that screen coordinates correspond to
            %tan(degrees of visual angle)

            td = transformToDegrees(params.cal);
            rect = td(params.cal.rect);
            glOrtho(rect(1), rect(3), rect(4), rect(2), -10, 10);

            glEnable(GL.TEXTURE_2D);
            glEnable(GL.BLEND);

            %set up vertex array state
            glEnableClientState(GL.VERTEX_ARRAY);
            %since texture coordinates can have four elements, the
            %third and fourth easily take care of order and phase.
            glEnableClientState(GL.TEXTURE_COORD_ARRAY);

            glEnableClientState(GL.COLOR_ARRAY);
            glEnable(GL.POINT_SMOOTH);
            glBlendFunc(GL.SRC_ALPHA, GL.ONE);

            %now load and compile the procedural Cauchy shader, if necessary
            if (~glIsProgram(program_))
                program_ = LoadGLSLProgramFromFiles(which('CauchyShader.frag.txt'));
            end
            
            glUseProgram(program_);
        end


        release = @r;
        function r()
            %when done with the cauchy shader...
            glUseProgram(0);
            %not supported? wtf?
            %glDeleteProgram(program_);
        end
    end


    function draw(window, next)
        if ~visible
            return;
        end
        
        [xy, angle, wavelength, order, width, color, phase] = source.get(next);
        %draw some GL points in the place for now...
        
        nQuads = size(xy, 2);
        
        %how many "sigma" to draw in width, so that all pixels with >
        %"accuracy" amplitude are plotted.
        c = max(abs(color), [], 1);
        sigma = single(real(sqrt(log(c ./ accuracy))));
        
        %how far to extend along the 'envelope' of the cauchy function, a
        %similar calculation.
        extent = tan(acos((accuracy./c).^(1./order)));
        
        %the wavelength of the peak spatial frequency is 
        
        phase = single(phase);
        order = single(order);
        
        %Now we're going to draw QUADS....
        %we need a vertex array, 4 xy-vertices each, making rectangles around
        %each point.
        
        %the "width" is 2-sigma; the wavelength of the peak spatial
        %frequency is adjusted for.
        
        %'extent/'sigma' determins how big the texture coordinate box is;
        %'boxlength'/'boxheight' is how bog the drawn coordinate box is.
        
        boxlength = wavelength.*order.*extent/pi/2;
        boxheight = width.*sigma/2;
        x0 = -cos(angle).*boxlength - sin(angle).*boxheight; % a row vector
        y0 =  sin(angle).*boxlength - cos(angle).*boxheight; % a column vector
        x1 = -cos(angle).*boxlength + sin(angle).*boxheight; % a row vector
        y1 =  sin(angle).*boxlength + cos(angle).*boxheight; % a column vector
        %      x0;  y0;   x1;   y1;    x2;    y2;   x3;    y3
        vertices = repmat(single(xy), 4, 1) + [x0; y0; x1; y1; -x0; -y0; -x1; -y1];
        
        %we need a texture coordinate array, also. But texture coordinates
        %have 4 components! (x, y, phase, order)
        %note that repmat is slow, and there are faster ways...

        textureCoords = ...
            [ -extent;-sigma;phase;order ...
            ; -extent; sigma;phase;order ...
            ;  extent; sigma;phase;order ...
            ;  extent;-sigma;phase;order];

        %colors...
        colors = repmat(single(color), 4, 1);

        Screen('BeginOpenGL', window);

        glPolygonMode(GL.FRONT_AND_BACK, GL.FILL)
        %glUseProgram(program_);
        glVertexPointer(2, GL.FLOAT, 0, vertices);
        glTexCoordPointer(4, GL.FLOAT, 0, textureCoords);
        glColorPointer(3, GL.FLOAT, 0, colors);
        glDrawArrays(GL.QUADS, 0, nQuads*4);
        
        
        if splitTextures_ %we have drawn the positive-going half, now need the negative
            textureCoords([3 7 11 15],:) = phase([1 1 1 1],:) + pi;
            glBlendEquation(GL.FUNC_REVERSE_SUBTRACT);
            glDrawArrays(GL.QUADS, 0, nQuads*4);
            glBlendEquation(GL.FUNC_ADD);
        end
        
        %glUseProgram(0);
        
        %temp: draw some lines, to show how our accuracy- clipping works
        %glPolygonMode(GL.FRONT_AND_BACK, GL.LINE);
        %glDrawArrays(GL.QUADS, 0, nQuads*4);
        
        Screen('EndOpenGL', window);
    end

    function update(frames)
        frameCount_ = frameCount_ + frames;
    end
end