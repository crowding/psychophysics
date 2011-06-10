function spattern(flange, fwidth, cross1, cross2)

if ~exist('cross2', 'var')
    cross2 = cross1;
end

[az, el] = view;
    
nspo = numel(cross1) + numel(cross2);

ax = gca;

plot3(ax...
    , sin(linspace(0,2*pi, nspo+1)), cos(linspace(0,2*pi, nspo+1)), zeros(1, nspo+1), 'k-'...
    , flange * sin(linspace(0,2*pi, nspo+1)), flange * cos(linspace(0,2*pi, nspo+1)), zeros(1, nspo+1) +fwidth/2, 'k-' ...
    , flange * sin(linspace(0,2*pi, nspo+1)), flange * cos(linspace(0,2*pi, nspo+1)), zeros(1, nspo+1) -fwidth/2, 'k-');

hold(ax, 'on'); axis equal
h1 = line ...
    ( [flange * sin(tlinspace(0,2*pi, nspo/2)             ); sin(tlinspace(0, 2*pi, nspo/2) + 4*pi/nspo*cross1(:)')            ] ...
    , [flange * cos(tlinspace(0,2*pi, nspo/2)             ); cos(tlinspace(0, 2*pi, nspo/2) + 4*pi/nspo*cross1(:)')            ] ...
    , bsxfun(@plus, zeros(1, nspo/2), [fwidth/2;0]) ...
    );
h2 = line ...
    ( [flange * sin(tlinspace(0,2*pi, nspo/2) + 2*pi/nspo ); sin(tlinspace(0, 2*pi, nspo/2) + 4*pi/nspo*cross2(:)' + 2*pi/nspo)] ...
    , [flange * cos(tlinspace(0,2*pi, nspo/2) + 2*pi/nspo ); cos(tlinspace(0, 2*pi, nspo/2) + 4*pi/nspo*cross2(:)' + 2*pi/nspo)] ...
    , bsxfun(@plus, zeros(1, nspo/2), [-fwidth/2;0]) ...
    );

set(h1, 'Color', [0 0 1]);
set(h2, 'Color', [0 0.5 0]);
hold(ax, 'off');
view(az, el);
end

function x =  tlinspace(a, b, n)
    %truncated linspace
    x = linspace(a, b, n+1);
    x(:,end) = [];
end