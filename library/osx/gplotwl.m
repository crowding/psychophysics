function [Xout,Yout]=gplotwl(A,xy,labelsca, lc)
% function [Xout,Yout]=gplotwl(A,xy,labelsca, lc)
%GPLOT Plot graph, as in "graph theory".
%   GPLOTWL(A,xy) plots the graph specified by A and xy. A graph, G, is
%   a set of nodes numbered from 1 to n, and a set of connections, or
%   edges, between them.  
%
%   In order to plot G, two matrices are needed. The adjacency matrix,
%   A, has a(i,j) nonzero if and only if node i is connected to node
%   j.  The coordinates array, xy, is an n-by-2 matrix with the
%   position for node i in the i-th row, xy(i,:) = [x(i) y(i)].
%   NEW - If A's non zero weights are not all the same than for each 
%   edge of the graph, its weight will be overlaid (i.e. text) at the
%   edges center point.
%   
%   GPLOTWL(A,xy,labelsca) - labelsca - user text label for nodes in a form suitable
%       for a vector call to text (i.e. cell array or padded string matrix - see text).
%       If empty no labels are drawn.
%   
%   GPLOTWL(A,xy,labelsca, lc) uses line type and color specified in the
%   string lc. See PLOT for possibilities.
%
%   [X,Y] = GPLOTWL(A,xy) returns the NaN-punctuated vectors
%   X and Y without actually generating a plot. These vectors
%   can be used to generate the plot at a later time if desired.
%   
%   See also SPY, TREEPLOT.

%   John Gilbert, 1991.
%   Modified 1-21-91, LS; 2-28-92, 6-16-92 CBM.
%   Copyright 1984-2001 The MathWorks, Inc. 
%   $Revision: 5.11 $  $Date: 2001/04/15 12:00:10 $
%   weights and node text capability by Andrew Diamond 11/8/1
[i,j,w] = find(A);
[ignore, p] = sort(max(i,j));
i = i(p);
j = j(p);
w = w(p);
% Create a long, NaN-separated list of line segments,
% rather than individual segments.

X = [ xy(i,1) xy(j,1) repmat(NaN,size(i))]';
Y = [ xy(i,2) xy(j,2) repmat(NaN,size(i))]';
X = X(:);
Y = Y(:);

if nargout==0,
    if nargin<4,
        plot(X, Y)
    else
        plot(X, Y, lc);
    end
else
    Xout = X;
    Yout = Y;
end
hold on;
plot(xy(:,1), xy(:,2), 'g.');
if(max(w) - min(w) > 0)
    cxs = (xy(i,1)  + xy(j,1)) ./ 2;
    cys = (xy(i,2)  + xy(j,2)) ./ 2;
    weighttextsca = cell(size(cxs));
    for iw=1:length(w)
        weighttextsca{iw} = num2str(w(iw)); % sprintf('%f',w(iw))
    end
    text(cxs, cys, weighttextsca);
    % plot weights at center of segments
end
if(nargin < 3)
    labelsca=[];
end
if(~isempty(labelsca))
    text(xy(:,1), xy(:,2), labelsca, 'FontWeight', 'bold');
    % plot node labels;
end
