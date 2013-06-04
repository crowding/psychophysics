function this = CircularGratingDrawer(varargin)
    global GL_;

    visible = 0;

    %the "source" is an object that determines where and how to draw each
    %grating for each frame. It has one method, get(next, refresh),
    %next being the timestamp and refresh being the refresh count. Its
    %return arguments are:
    %[x, y, radius, width, color, lobes, phase]

    source = SimpleCircularGratingSource();

    %the handle for the shader program
    persistent program_;
    if (isempty(program_))
        program_ = -1;
    end

    %this determines how large a shader patch to draw
    accuracy = 0.005;
    drawBox = 0;

    splitTextures_ = 0;
    toPixels_ = @noop;

    persistent init__;
    this = autoobject(varargin{:});

    function [release, params] = init(params)
    %initialize the openGL environment, shader, and texture.
    %we initialize the environment to measure in the same degrees as we
    %are calibrated to...
        AssertGLSL;
        params = require(params, screenGL(params.window), @setupOpenGL);
        toPixels_ = transformToPixels(params.cal);

        function params = setupOpenGL(params)
            %figure out whether we are in a 16-bit buffer?
            if (params.screenInfo.BitsPerColorComponent > 8)...
                    && (params.screenInfo.GLSupportsBlendingUpToBpc ...
                        >= params.screenInfo.BitsPerColorComponent)
                %we are running in a high-dynamic-range buffer with
                %blending, yay
                splitTextures_ = 0;
            else
                %boo
                splitTextures_ = 1;
            end

            %feel like I should be pushing/popping GL contexts after
            %setting this up
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
            %third and fourth takes care of "width" and "lobes"
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
                        program_ = LoadGLSLProgramFromFiles( ...
                            which('CircularGratingShader.frag.txt'));
                        glUseProgram(program_);
                    end
                else
                    program_ = LoadGLSLProgramFromFiles(...
                        which('CircularGratingShader.frag.txt'));
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

    onsetTime_ = NaN;

    function draw(window, next)
        if visible && isnan(onsetTime_)
            onsetTime_ = next;
        end
        if ~visible || next < onsetTime_
            return;
        end
        if ~iscell(source)
            [xy, radius, width, color, lobes, phase] = ...
                source.get(next - onsetTime_);
        else
            out1 = cell(numel(source), 6);
            for i = 1:numel(source)
                [out1{i,:}] = source{i}.get(next - onsetTime_);
            end

            out2 = cell(1,3);
            for i = 1:6
                % is there seriously not a way to do this?
                out2{i} = cat(1, out1{:,i});
            end

            [xy, radius, width, color, lobes, phase] = out2{:};
        end

        nQuads = size(xy, 2);

        if nQuads == 0
            return;
        end

        %how many "sigma" to draw in width, so that all pixels with >
        %"accuracy" amplitude are plotted.
        c = max(abs(color), [], 1);
        sigma = single(real(sqrt(log(c ./ accuracy))));

        %how big the box in screen space
        bs = radius + abs(width.*sigma); %box-size
        vertices = repmat(single(xy), 4, 1) + ...
            [bs; bs; -bs; bs; -bs; -bs; bs; -bs];

        %how big the box in texture coord space
        %texture coords are normalized to radius being always 1
        extent = single(bs./radius);

        %handle phasing by rotation in texture coords
        x0 = sqrt(2) * extent .* cos(pi/4+mod(phase,2*pi)./lobes);
        x1 = sqrt(2) * extent .* sin(pi/4+mod(phase,2*pi)./lobes);
        x0(lobes == 0) = extent(lobes==0);
        x1(lobes == 0) = extent(lobes==0);

        texSigma = width./radius./2;
        textureCoords = ...
            [ x0; x1;texSigma;lobes ...
            ; x1;-x0;texSigma;lobes ...
            ;-x0;-x1;texSigma;lobes ...
            ;-x1; x0;texSigma;lobes];

        colors = repmat(single(color), 4, 1);

        Screen('BeginOpenGL', window);

        glPolygonMode(GL_.FRONT_AND_BACK, GL_.FILL)
        glUseProgram(program_);
        glVertexPointer(2, GL_.FLOAT, 0, vertices);
        glTexCoordPointer(4, GL_.FLOAT, 0, textureCoords);
        glColorPointer(3, GL_.FLOAT, 0, colors);
        glDrawArrays(GL_.QUADS, 0, nQuads*4);

        if splitTextures_ %we have drawn the positive-going half, now need the negative
            error('not doing this');
            textureCoords([3 7 11 15],:) = phase([1 1 1 1],:) + pi; %#ok, it is used by DrawArrays
            glBlendEquation(GL_.FUNC_REVERSE_SUBTRACT);
            glDrawArrays(GL_.QUADS, 0, nQuads*4);
            glBlendEquation(GL_.FUNC_ADD);
        end

        Screen('EndOpenGL', window);

        if drawBox
             vertices = reshape(toPixels_(...
                 double(vertices([1 2 3 4 3 4 5 6 5 6 7 8 7 8 1 2],:))), 2, []);
            Screen('DrawLines', window, vertices, [], 0, [], 1);
        end
    end

    function update(frames)
    end

    function v = setVisible(v, t)
        visible = v;
        if nargin >= 2
            %track the onset time..
            onsetTime_ = t;
        else
            if visible == 0
                onsetTime_ = NaN;
            end
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