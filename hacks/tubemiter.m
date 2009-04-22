function m = tubemiter(ID0, OD0, OD1, transform)

%function m = tubemiter(ID0, OD0, OD1, transform)
%
%create a template for tube mitering that you print out and wrap around the tube.
%The template shows where
%the outside and inside edge of the mitered tube should be.
%
%Note, you may wish to add a smidge to OD0 for the thickness of the paper.
%Ha.
%
%Imagine the tube to be mitered as a cylinder oriented along the z-axis.
%Then each incident tube is defined as another cylinder, then rotated.
%
%the 'transform' is a 4x4 transform matrix in affine coordinates, to be
%applied to the sedon cylinder. for convenience there should be functions
%rotate{x,y,z}(...) translate{x,y,z} to create these matrices.
%
%For instance, to create a miter for a 1.375"x0.55" wall top tube to a 1.5" OD head
%tube at a rake angle of 74 degrees (i.e. 106 dg. inside angle:
%
%
%  ___     _   _      _     __     __  _____     _   _    ___  
% |_ _|   | | | |    / \    \ \   / / | ____|   | \ | |  / _ \ 
%  | |    | |_| |   / _ \    \ \ / /  |  _|     |  \| | | | | |
%  | |    |  _  |  / ___ \    \ V /   | |___    | |\  | | |_| |
% |___|   |_| |_| /_/   \_\    \_/    |_____|   |_| \_|  \___/ 
%                                                              
%  ____       _      _   _   _____   ____  
% |  _ \     / \    | \ | | |_   _| / ___| 
% | |_) |   / _ \   |  \| |   | |   \___ \ 
% |  __/   / ___ \  | |\  |   | |    ___) |
% |_|     /_/   \_\ |_| \_|   |_|   |____/
%
%
%
%tubemiter(1.265, 1.375, 1.5, rotatex(106))

%the equation of the incident cylinder is, in its home coordinates Y,
%x^2 + y^2 = r^2, or in affine representation,

%Y' [-1/r^2 -1/r^2 0   0  
%    0       0     0   0  
%    0       0     0   0  
%    0       0     0   1 ] Y = 0

R = [1 1 0 0 ; 0 0 0 0; 0 0 0 0; 0 0 0 -r^2]

%Now if we have a transform X = TY (coresponding to the placement of the
%cylinder) we have the equation as:

% X' T'RT X = 0

%Now we iterate through, setting X(1) and X(2) and X(4) and solving for X(3)...

fplot(@(z)findz(OD0, [0 2*pi], 'b-');

    function z = findz(angle, diameter)
        %we have the equation X' T'RT X = 0, where three of four components of X
        %are known. angle and diameter should be scalar or column vectors.
        %I suppose we could work out the coefficients explicitly, but this
        %following is more intuitive omputationally:

        z_1 = [diameter.*sin(angle); diameter.*cos(angle); -ones(size(angle));  ones(size(angle))];
        z0  = [diameter.*sin(angle); diameter.*cos(angle);  zeros(size(angle)); ones(size(angle))];
        z1  = [diameter.*sin(angle); diameter.*cos(angle); -ones(size(angle));  ones(size(angle))];

        f_1 = z_1'*T'*R*T*z_1;
        f0 = z0'*T'*R*T*z0;
        f1 = z1'*T'*R*T*z1;

        %this gives us a quadratic equation in z, here are the coefficients:
        c = f0;
        b = (f1 - f_1) / 2;
        a = ((f1 + f_1) - 2*f0) / 2

        %solve for z
        z = (-b - sqrt(b.^2 - 4.*a.*c)) / 2.*a;
    end

end