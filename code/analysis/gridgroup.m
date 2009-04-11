function [g, varargout] = gridgroup(parameters, varargin)
%function [g, varargout] = gridgroup(parameters, varargin)
%Takes a number of arguments that each have the same numbr of elements as
%there are columns in PARAMETERS. Groups them each into unique bins as
%determined by the unique columns of PARAMETERS. G gives the parameter values
%corresponding to each bin.

%each column of parameters is a different parameter to group by
mat2cellargs = num2cell(size(parameters));
mat2cellargs{1} = ones(1,mat2cellargs{1}); %#ok, why does it complain here?
paramrows = mat2cell(parameters, mat2cellargs{:});
[b, i, j] = cellfun(@unique, paramrows, 'UniformOutput', 0);

%this gives us the dimensions of the groups. 

%J gives the index within the
%group for each parameter.

%concatenate J to get each element's spot in the grid
indices = cat(1, j{:});

[allgroups, alli, allj] = unique(indices', 'rows');

allgroups = allgroups';

for argix = 1:numel(varargin)
    in = varargin{argix};
    sz = cellfun('prodofsize', b(:)');
    if numel(sz) == 1
        sz(2) = 1; %GRRRRRRR fucking why does matlab assume 'square' if you give cell() etc. one argument
    end
    grid = cell(sz);
    %populate the grid...
    for bin = 1:numel(alli) %each column...
        
        ix = num2cell(allgroups(:,bin));
        
        grid{ix{:}} = in(allj == bin);
    end
    varargout{argix} = grid;
end

%the first output lists the parameters that were grouped
g = cell(1, numel(b)+1); %each distinct value for each parameter
[g{:}] = ndgrid(1,b{:});
g(1) = [];
%concatenate then split 'em up
g = cat(1, g{:});
mat2cellargs = arrayfun(@(x)ones(1,x), size(g), 'UniformOutput', 0);
mat2cellargs{1} = numel(b);
g = mat2cell(g, mat2cellargs{:});
g = shiftdim(g, 1);