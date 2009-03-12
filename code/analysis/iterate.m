function varargout = iterate(dims, fn, varargin)
%function varargout = iterate([dims], fn, varargin)
%
%Similar to python iterate... but with a provision for multidimensional
%iteration. On each loop the first argument passed to fn is an index
%vector, and subsequent arguments are slices of each input.
%
%Wackiness: if the dims argument is given as a cell, then  
%
%for instance:
%iterate(@(x,y)disp({x y}), 1:10) 

% iterate(@(x,y)disp({x y}), reshape(10:10:90,3,3))
%     [1]    [10]
%     [2]    [20]
%     [3]    [30]
%     [4]    [40]
%     [5]    [50]
%     [6]    [60]
%     [7]    [70]
%     [8]    [80]
%     [9]    [90]

    if isa(dims, 'function_handle')
        %one dimensional iteration. fill in the dims and use a linear
        %index.
        varargin = {fn varargin{:}};
        fn = dims;
        dims = {1};
        varargin = cellfun(@(x)x(:), varargin, 'UniformOutput', 0);
    end
    %varargin must always be the same size
    sz = size(varargin{1});
    for i = 1:numel(varargin)
        if ~isequal(size(varargin{i}), sz)
            error('iterate:elementsNotSameSize', 'Input arguments to iterate must be the same size...');
        end
    end
    
    nd = numel(dims);
    
    if iscell(dims)
        stripcell = 1;
    else
        stripcell = 0;
    end

    invdims = 1:ndims(varargin{1});
    invdims(dims) = [];
    perm = [dims(:)' invdims];
    varargin = cellfun(@(x)n2c(permute(x, perm), nd+1:ndims(x), stripcell), varargin, 'UniformOutput', 0);

    %what makes ITERATE ITERATE is the index argument. Note it is a
    %collapsed index that includes only the slices taken from each dim. And
    %each argument has the iterated dimention collapsed out of it.
    ndgridargs = arrayfun(@(d)1:size(varargin{1}, d), 1:nd, 'UniformOutput', 0);
    [indices{1:nd}] = ndg(ndgridargs{:});
    indices = cat(nd+1, indices{:});
    indices = reshape(n2c(permute(indices, [nd+1 1:nd]), 1), size(varargin{1}));
    
    %NOW....
    [varargout{1:nargout}] = cellfun(fn, indices, varargin{:});
end

function out = n2c(in, dims, stripcell)
    %yay matlab. there is no reason why num2cell(x) ought to behave
    %differently from num2cell(x, []). The second argument is a
    %list of dimensions to be taken together, and the default behavior in
    %absence of the second argument is not to take any dimensions together.
    %Yet giving the empty list as second argument crashes. WTF.
    if isempty(dims)
        %in a logical world this would not be necessary
        out = num2cell(in);
    else
        out = num2cell(in, dims);
    end
end

function varargout = ndg(varargin)
    %doubleyou tee f. You'd think that ndgrid, being named with ND like it
    %would work with problems of any dimensionality, would work in cases
    %with one or zero dimensions. matlab strikes again.
    switch nargin
        case 0
            varargout = {};
        case 1
            varargout = {varargin{1}(:)};
        otherwise
            [varargout{1:nargout}] = ndgrid(varargin{:});
    end
end