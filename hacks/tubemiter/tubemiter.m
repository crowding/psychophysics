function m = tubemiter(ID0, OD0, varargin)

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
%the 'transform' is a 4x4 affine transform matrix, to be
%applied to the incident cylinder. for convenience there should be functions
%rotate{x,y,z}(...) translate([x, y, z]) to create these matrices.
%
%For instance, to create a miter for a 1.375"x0.55" wall top tube to a 1.5" OD head
%tube at a rake angle of 74 degrees (i.e. 106 dg. inside angle:
%
%tubemiter(1.265, 1.375, 1.5, rotatex(106))

%the equation of the incident cylinder is, in its home coordinates Y,
%x^2 + y^2 = r^2, or in affine representation,

%Y' [-1/r^2  0     0   0  
%    0      -1/r^2 0   0  
%    0       0     0   0  
%    0       0     0   1 ] Y = 0


%Now if we have a transform X = TY (coresponding to the placement of the
%cylinder) we have the equation as:

% X' T'RT X = 0

%T = transform;
figure(1); clf;

ODs = varargin(1:2:end);
transforms = varargin(2:2:end);

%Now we iterate through, setting X(1) and X(2) and X(4) and solving for X(3)...
cellfun(@plotit, ODs, transforms);
    function f = plotit(OD, T)
        R = [-1/(OD/2)^2 0 0 0 ; 0 -1/(OD/2)^2 0 0; 0 0 0 0; 0 0 0 1];

        fplot(@(a)findz(a / (OD0/2), OD0/2), [0 2*pi]*OD0/2, 1000, 'r-');
        hold on;
        fplot(@(a)findz(a / (OD0/2), ID0/2), [0 2*pi]*OD0/2, 1000, 'b-');
        function z = findz(angle, radius)
            %we have the equation X' T'RT X = 0, where three of four components of X
            %are known. angle and diameter should be scalar or column vectors.
            %I suppose we could work out the coefficients explicitly, but this
            %following is more intuitive computationally:

            z_1 = [radius.*sin(angle); radius.*cos(angle); -ones(size(angle));  ones(size(angle))];
            z0  = [radius.*sin(angle); radius.*cos(angle);  zeros(size(angle)); ones(size(angle))];
            z1  = [radius.*sin(angle); radius.*cos(angle);  ones(size(angle));  ones(size(angle))];

            f_1 = z_1'*T'*R*T*z_1;
            f0 =  z0'* T'*R*T*z0;
            f1 =  z1'* T'*R*T*z1;

            %this gives us a quadratic equation in z, here are the coefficients:
            c = f0;
            b = (f1 - f_1) / 2;
            a = ((f1 + f_1) - 2*f0) / 2;

            %solve for z
            z = (-b + [1 -1] .* sqrt(b.^2 - 4.*a.*c)) / (2.*a);

            z(boolean(imag(z))) = NaN;
        end
    end
plot([0 2*pi]*OD0/2, [0 0], 'k:');

%set up this plot and axes to print at the right size....

axis equal;
set(gca, 'position', [0 0 1 1]);
ps = get(gcf, 'PaperSize');
set(gcf, 'PaperPosition', [ps(1)/2 - (OD0*pi/2), 0, OD0*pi, ps(2)]);
plot([pi pi]*OD0/2, [-ps(2)/2 ps(2)/2], 'k:');
hold off;
set(gca, 'YLim', [-ps(2)/2 ps(2)/2]);
set(gca, 'XLim', [0 pi]*OD0);
set(gca, 'XTick', [0]);
set(gca, 'XTickLabel', []);
set(gca, 'YTick', [0]);
set(gca, 'YTickLabel', []);

%finally, we ought to show the actual cylinders, in a second display.
%{
param = linspace(0, 2*pi, 1000);
outside = arrayfun(@(a) findz(a, OD0/2), param, 'UniformOutput',0);
outside = cat(1, outside{:});
inside = arrayfun(@(a) findz(a, ID0/2), param, 'UniformOutput',0);
inside = cat(1, inside{:});
%}


%figure(2); clf;
%plot3(sin(param)*OD0/2, cos(param)*OD0/2, outside, 'b-', sin(param)*ID0/2, cos(param)*ID0/2, inside, 'b--');
%axis equal;

%xlabel x; ylabel y; zlabel z;


end