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
    
    persistent init__;
    this = autoobject(varargin);
    
    function setVisible(s)
        visible = s;
    end

    frameCount_ = 0;

    function [release, params] = init(params)
        %initialize the openGL environment, shader, and texture.
        %we initialize the environment to measure in the same degrees as we
        %are calibrated to...
        
        [release, params] = require(params, @setupOpenGL_);
        
        function [release, params] = setupOpenGL_(params)
            params = require(params, screenGL(params.window), @doSetup);
            
            function params = doSetup(params)
                glDisable(GL.DEPTH_TEST);
                glMatrixMode(GL.PROJECTION);

                glLoadIdentity;

                frameCount_ = 0;

                %set up a projection so that screen coordinates correspond to
                %tan(degrees of visual angle)

                %note i may want to mix up opengl contextx

                td = transformToDegrees(params.cal);
                rect = td(params.cal.rect);
                glOrtho(rect(1), rect(3), rect(4), rect(2), -10, 10);

                glEnable(GL.TEXTURE_2D);
                glEnable(GL.BLEND);

                %set up vertex array state
                glEnableClientState(GL.TEXTURE_COORD_ARRAY);
                glEnableClientState(GL.VERTEX_ARRAY);
                glEnableClientState(GL.COLOR_ARRAY);
                glEnableClientState(GL.COLOR_ARRAY);
                glEnable(GL.POINT_SMOOTH);
                glEnableVertexAttribArray(0); %enable the vertex attribute array...

                %set up for additive blending
                glBlendFunc(GL.SRC_ALPHA, GL.ONE);

                %the texture coordinates control the drawing, and the vertex
                %coordinates
            end
            
            release = @r;
            function r()
                
            end
        end
    end

    function draw(window, next)
        Screen('BeginOpenGL', window)
        [xy, angle, wavelength, order, width, color, phase] = source.get(next);
        %draw some GL points in the place for now...
        glPointSize(single(50));
        
        glBegin(GL.POINTS)

        for i = 1:size(xy, 2)
            glColor3dv(color(:,i));
            glVertex2dv(xy(:,i));
        end

        glEnd();
        Screen('EndOpenGL', window)
    end

    function update(frames)
        frameCount_ = frameCount_ + frames;
    end
end