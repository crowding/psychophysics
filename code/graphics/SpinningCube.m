function this = SpinningCube(varargin)

    % a debugging port of spinningCubeDemo into my drawing routines.

    % Initialize amount and direction of rotation
    theta=0;
    rotatev=[ 0 0 1 ];
    texname = [];


    persistent init__;
    this = autoobject(varargin{:});
    

    function [release, params] = init(params)
        [release, params] = require(params, @glSection_, @init_);
    end

    function [release, params] = glSection_(params)
        Screen('BeginOpenGL', params.window);
        release = @r;
        function r()
            Screen('EndOpenGL', params.window);
        end
    end

    function [release, params] = init_(params)
        global GL;

        % Get the aspect ratio of the screen:
        ar=params.cal.rect(4)/params.cal.rect(3);
        
        glEnable(GL.LIGHTING);
        glEnable(GL.LIGHT0);

        % Enable two-sided lighting - Back sides of polygons are lit as well.
        glLightModelfv(GL.LIGHT_MODEL_TWO_SIDE,GL.TRUE);

        % Enable proper occlusion handling via depth tests:
        glEnable(GL.DEPTH_TEST);

        % Define the cubes light reflection properties by setting up reflection
        % coefficients for ambient, diffuse and specular reflection:
        glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT, [ .33 .22 .03 1 ]);
        glMaterialfv(GL.FRONT_AND_BACK,GL.DIFFUSE, [ .78 .57 .11 1 ]);
        glMaterialfv(GL.FRONT_AND_BACK,GL.SHININESS,27.8);

        % Enable 2D texture mapping, so the faces of the cube will show some nice
        % images:
        glEnable(GL.TEXTURE_2D);

        % Generate 6 textures and store their handles in vecotr 'texname'
        texname=glGenTextures(6);
        
        matdemopath = [PsychtoolboxRoot 'PsychDemos/OpenGL4MatlabDemos/mogldemo.mat'];
        load(matdemopath, 'face')
        
        % Setup textures for all six sides of cube:
        for i=1:6,
            % Enable i'th texture by binding it:
            glBindTexture(GL.TEXTURE_2D,texname(i));
            % Compute image in matlab matrix 'tx'
            f=max(min(128*(1+face{i}),255),0);
            tx=repmat(flipdim(f,1),[ 1 1 3 ]);
            tx=permute(flipdim(uint8(tx),1),[ 3 2 1 ]);
            % Assign image in matrix 'tx' to i'th texture:
            glTexImage2D(GL.TEXTURE_2D,0,GL.RGB,256,256,0,GL.RGB,GL.UNSIGNED_BYTE,tx);
            % Setup texture wrapping behaviour:
            glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_WRAP_S,GL.REPEAT);
            glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_WRAP_T,GL.REPEAT);
            % Setup filtering for the textures:
            glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_MAG_FILTER,GL.NEAREST);
            glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_MIN_FILTER,GL.NEAREST);
            % Choose texture application function: It shall modulate the light
            % reflection properties of the the cubes face:
            glTexEnvfv(GL.TEXTURE_ENV,GL.TEXTURE_ENV_MODE,GL.MODULATE);
        end
        
        % Set projection matrix: This defines a perspective projection,
        % corresponding to the model of a pin-hole camera - which is a good
        % approximation of the human eye and of standard real world cameras --
        % well, the best aproximation one can do with 3 lines of code ;-)
        glMatrixMode(GL.PROJECTION);
        glLoadIdentity;
        % Field of view is 25 degrees from line of sight. Objects closer than
        % 0.1 distance units or farther away than 100 distance units get clipped
        % away, aspect ratio is adapted to the monitors aspect ratio:
        gluPerspective(25,1/ar,0.1,100);

        % Setup modelview matrix: This defines the position, orientation and
        % looking direction of the virtual camera:
        glMatrixMode(GL.MODELVIEW);
        glLoadIdentity;

        % Cam is located at 3D position (3,3,5), points upright (0,1,0) and fixates
        % at the origin (0,0,0) of the worlds coordinate system:
        gluLookAt(3,3,5,0,0,0,0,1,0);

        % Setup position and emission properties of the light source:

        % Set background color to 'black':
        glClearColor(0,0,0,0);

        % Point lightsource at (1,2,3)...
        glLightfv(GL.LIGHT0,GL.POSITION,[ 1 2 3 0 ]);
        % Emits white (1,1,1,1) diffuse light:
        glLightfv(GL.LIGHT0,GL.DIFFUSE, [ 1 1 1 1 ]);

        % There's also some white, but weak (R,G,B) = (0.1, 0.1, 0.1)
        % ambient light present:
        glLightfv(GL.LIGHT0,GL.AMBIENT, [ .1 .1 .1 1 ]);
        
        glEnable(GL.BLEND);
        glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

        release = @noop;
    end

    function draw(window, next)
        global GL;
        Screen('BeginOpenGL', window)
        
        % Setup cubes rotation around axis:
        glPushMatrix;
        glRotated(theta,rotatev(1),rotatev(2),rotatev(3));

        % Clear out the backbuffer: This also cleans the depth-buffer for
        % proper occlusion handling:
        glClear;

        % The subroutine cubeface (see below) draws one side of the cube, so we
        % call it six times with different settings:
        cubeface_([ 4 3 2 1 ],texname(1));
        cubeface_([ 5 6 7 8 ],texname(2));
        cubeface_([ 1 2 6 5 ],texname(3));
        cubeface_([ 3 4 8 7 ],texname(4));
        cubeface_([ 2 3 7 6 ],texname(5));
        cubeface_([ 4 1 5 8 ],texname(6));
        glPopMatrix;
        Screen('EndOpenGL', window)
    end

    function update(frames)
        for i = 1:frames
            % Calculate rotation angle for next frame:
            theta=mod(theta+0.3,360);
            rotatev=rotatev+0.1*[ sin((pi/180)*theta) sin((pi/180)*2*theta) sin((pi/180)*theta/5) ];
            rotatev=rotatev/sqrt(sum(rotatev.^2));
        end
    end

    function cubeface_( i, tx )

        % We want to access OpenGL constants. They are defined in the global
        % variable GL. GLU constants and AGL constants are also available in the
        % variables GLU and AGL...
        global GL;

        % Vector v maps indices to 3D positions of the corners of a face:
        v=[ 0 0 0 ; 1 0 0 ; 1 1 0 ; 0 1 0 ; 0 0 1 ; 1 0 1 ; 1 1 1 ; 0 1 1 ]'-0.5;
        % Compute surface normal vector. Needed for proper lighting calculation:
        n=cross(v(:,i(2))-v(:,i(1)),v(:,i(3))-v(:,i(2)));

        % Bind (Select) texture 'tx' for drawing:
        glBindTexture(GL.TEXTURE_2D,tx);
        % Begin drawing of a new polygon:
        glBegin(GL.POLYGON);

        % Assign n as normal vector for this polygons surface normal:
        glNormal3dv(n);

        % Define vertex 1 by assigning a texture coordinate and a 3D position:
        glTexCoord2dv([ 0 0 ]);
        glVertex3dv(v(:,i(1)));
        % Define vertex 2 by assigning a texture coordinate and a 3D position:
        glTexCoord2dv([ 1 0 ]);
        glVertex3dv(v(:,i(2)));
        % Define vertex 3 by assigning a texture coordinate and a 3D position:
        glTexCoord2dv([ 1 1 ]);
        glVertex3dv(v(:,i(3)));
        % Define vertex 4 by assigning a texture coordinate and a 3D position:
        glTexCoord2dv([ 0 1 ]);
        glVertex3dv(v(:,i(4)));
        % Done with this polygon:
        glEnd;

        % Return to main function:
    end

end