function [addtex, subtex, texcoords, screencoords, onset] = gl_textures(this, w, cal);
% function [addtex, subtex, texcoords, screencoords, onset] = gl_textures(this, w, cal);
%
% Generates GL textures to serve as offscreen pixmaps to display the given
% Patch as an animation.
%
% inputs:
%
% this : a Patch object.
% w : an open Psychtoolbox window.
% cal: a Calibration object for the window.
%
% outputs:
%
% addtex : a Gl texture to be added to the screen.
% subtex : a GL texture to be subtracted from the screen.
% texcoords : Normalized texture coordinates for the GL_QUAD object.
%             There is one column per frame.
% screencoords : Where to draw the quad on screen (in degrees.) There is
%                only one column, since the column
% onset : the time at which the first frame should be shown, if the patch
%         were to be centered at t=0.

global GL;

[x, y, t] = sampling(this, this, cal);

onset = t(1);

z = evaluate(this, x, y, t);

maxtex = 0;
require(screenGL(w), @getmaxtex);
    function getmaxtex(x)
        maxtex = double(glGetIntegerv(GL.MAX_TEXTURE_SIZE));
    end

%we will be using a large texture as a sort of offscreen pixmap.
hsize = length(x);              %horizontal size of each frame
vsize = length(y);              %vertical size of each frame
nh = floor(maxtex/hsize);       %how many frames per row of texture
nv = ceil(length(t)/nh);        %how many rows of frames
n = length(t);                  %how many frames, total

%add and sub are in column-major order for now.
tv = pot(vsize*nv); %vertical texture size
th = pot(hsize*nh); %horizontal texture size

if (tv > maxtex)
    error('gl_textures:patch_too_big', ...
        ['Could not render the patch into one GL texture.'...
        ' Consider making the sprite player work over multiple textures.']);
end

add = zeros(tv, th, 'uint8');
sub = zeros(tv, th, 'uint8');

tv = size(add, 1);              %texure to be subtracted
th = size(add, 2);              %texture to be added

%initialize arrays for the quad coordinates
texcoords = zeros(8,n); %to be filled in below
screencoords = [x(1), y(1), x(end), y(1), x(end), y(end), x(1), y(end)]';

%stuff each frame into the image matrices
for i = 0:n-1
    hslot = mod(i, nh);
    vslot = floor(i/nh);
    %the boundaries of the frame within the patch
    l = 1 + hslot * hsize;
    r = hsize + hslot * hsize;
    t = 1 + vslot*vsize;
    b = vsize + vslot*vsize;
    
    add(t:b, l:r) = uint8(z(:,:,i+1) * 255);
    sub(t:b, l:r) = uint8(-z(:,:,i+1) * 255);
    
    %normalized texture coordinates -- need to check the alignment on these
    l_n = (l-1)/th;
    r_n = (r-1)/th;
    t_n = (t-1)/tv;
    b_n = (b-1)/tv;

    texcoords(:,i+1) = [l_n t_n, r_n t_n, r_n b_n, l_n b_n]';
end

%make the image matrixes into GL textures.
require(screenGL(w), @maketextures);
function maketextures(params)
    glEnable(GL.TEXTURE_2D);
    texnames = glGenTextures(2);
    addtex = texnames(1);
    subtex = texnames(2);

    maketexture(addtex, add);
    maketexture(subtex, sub);
end

function maketexture(name, tx)
    glBindTexture(GL.TEXTURE_2D, name);
    tx = permute(tx, [2 1]);
    
    glTexImage2D(GL.TEXTURE_2D,0,GL.LUMINANCE8,size(tx,1),size(tx,2),0,GL.LUMINANCE,GL.UNSIGNED_BYTE,tx);
    glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_WRAP_S,GL.CLAMP);
    glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_WRAP_T,GL.CLAMP);
    glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_MAG_FILTER,GL.LINEAR);
    glTexParameterfv(GL.TEXTURE_2D,GL.TEXTURE_MIN_FILTER,GL.LINEAR);
    glTexEnvfv(GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, GL.MODULATE);
end

function xx = pot(x)
    %crazy, without the cast to 'double' in getmaxtex, this gets called
    %with an 'int32' argument. Apparently a double DIVIDED by an integer
    %returns an integer. WTF numeric type hierarchy matlab?
    xx = 2.^ceil(log2(x - 0.5));
end

end