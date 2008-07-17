function this = CauchyDrawer(varargin)

    AssertOpenGL;
    
    visible = 0;
    
    visible = 0;
    sigmas = 2.5; %how many "sigmas" to draw the patches' Gaussian profile
                  %over. The patch is drawn from the center to +- this
                  %amount.
    waves = 2; %how many "wavelengths" to draw the patches' Cauchy profile over.

    this = autoobject(varargin);
    
    function setVisible(s)
        visible = s;
    end

    function [release, params, next] = init(params)
        %initialize the openGL environment, shader, and texture.
        %we initialize the environment to measure in the same degrees as we
        %are calibrated to...
        global GL;
        
        [release, params] = require(params, ScreenGL(params.window), @setupOpenGL));
        
        function [release, params] = setupOpenGL_(params)
            glDisable(GL.DEPTH_TEST);
            glMatrixMode(GL.PROJECTION);
            
            glLoadIdentity;
            td = transormToDegrees(params.cal);
            rect = td(params.rect);
            glOrtho(rect(1), rect(3), rect(4), rect(2), -10, 10);
            
            glEnable(GL.TEXTURE_2D);
            glEnable(GL.BLEND);

            %set up for additive blending
            glBlendFunc(GL.SRC_ALPHA, GL.ONE);

            %set up vertex array state
            glEnableClientState(GL.TEXTURE_COORD_ARRAY);
            glEnableClientState(GL.VERTEX_ARRAY);
            glEnableClientState(GL.COLOR_ARRAY);
            glEnableClientState(GL.

            %set up for adding a 2-element vertex attribute?
            release = @r;
        end
    end
end