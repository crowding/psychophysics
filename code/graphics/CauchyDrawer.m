function this = CauchyDrawer(varargin)

    global GL_;

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

            glDisable(GL_.DEPTH_TEST);
            glMatrixMode(GL_.PROJECTION);

            glLoadIdentity;

            td = transformToDegrees(params.cal);
            rect = td(params.cal.rect);
            glOrtho(rect(1), rect(3), rect(4), rect(2), -10, 10);

            glEnable(GL_.TEXTURE_2D);
            glEnable(GL_.BLEND);

            %set up vertex array state
            glEnableClientState(GL_.VERTEX_ARRAY);
            %since texture coordinates can have four elements, the
            %third and fourth easily take care of order and phase.
            glEnableClientState(GL_.TEXTURE_COORD_ARRAY);

            glEnableClientState(GL_.COLOR_ARRAY);
            glEnable(GL_.POINT_SMOOTH);
            glBlendFunc(GL_.SRC_ALPHA, GL_.ONE);

            %now load and compile the procedural Cauchy shader, if necessary
            if (~glIsProgram(program_)) %this don't work???
                if program_ > 0
                    try
                        glUseProgram(program_);
                    catch
                        program_ = LoadGLSLProgramFromFiles(which('CauchyShader.frag.txt'));
                        glUseProgram(program_);
                    end
                else
                    program_ = LoadGLSLProgramFromFiles(which('CauchyShader.frag.txt'));
                    glUseProgram(program_);
                end
            else
                glUseProgram(program_);            
            end
        end

        release = @r;
        function r()
            %when done with the cauchy shader...
            glUseProgram(0);
            
            %not supported? wtf?
%            try 
%                glDeleteProgram(program_);
%            end
%            program_ = -1;
        end
    end

    onsetTime_ = 0;
    
    function draw(window, next)
        if ~visible || next < onsetTime_
            return;
        end
        
        if ~iscell(source)
            [xy, angle, wavelength, order, width, color, phase] = source.get(next - onsetTime_);
        else
            out1 = cell(7,numel(source), 7);
            for i = 1:numel(source)
                [out1{i,:}] = source{i}.get(next - onsetTime_);
            end

            out2 = cell(1,7);
            for i = 1:7
                % is there seriously not a way to do this?
                out2{i} = cat(1, out{:,i});
            end
                
            [xy, angle, wavelength, order, width, color, phase] = out2{:};
        end
        %draw some GL points in the place for now...
        
        nQuads = size(xy, 2);
        
        if nQuads == 0
            return;
        end
        
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

        glPolygonMode(GL_.FRONT_AND_BACK, GL_.FILL)
        %glUseProgram(program_);
        glVertexPointer(2, GL_.FLOAT, 0, vertices);
        glTexCoordPointer(4, GL_.FLOAT, 0, textureCoords);
        glColorPointer(3, GL_.FLOAT, 0, colors);
        glDrawArrays(GL_.QUADS, 0, nQuads*4);
        
        
        if splitTextures_ %we have drawn the positive-going half, now need the negative
            textureCoords([3 7 11 15],:) = phase([1 1 1 1],:) + pi; %#ok, it is used by DrawArrays
            glBlendEquation(GL_.FUNC_REVERSE_SUBTRACT);
            glDrawArrays(GL_.QUADS, 0, nQuads*4);
            glBlendEquation(GL_.FUNC_ADD);
        end
        
        %glUseProgram(0);
        
        %temp: draw some lines, to show how our accuracy- clipping works
        %glPolygonMode(GL.FRONT_AND_BACK, GL.LINE);
        %glDrawArrays(GL.QUADS, 0, nQuads*4);
        
        Screen('EndOpenGL', window);
    end

    function update(frames)
    end

    function v = setVisible(v, t)
        visible = v;
        if nargin >= 2
            %track the onset time..
            onsetTime_ = t;
        end
    end

    function l = getLoc(t)
        if nargin > 0
            l = source.getLoc(t - onsetTime_);
        else
            l = [0;0];
        end
    end
end