function varargout = iterate(dims, fn, varargin)
%function varargout = iterate([dims], fn, varargin)
%
%A looping function, like cellfun and arrayfun, but (a) also provides the loop
%body function with an array index and (b) can loop over slices of the
%input arrays, rather than 
%Inspired by python iterate() but with
%a provision for multidimensional iteration. On each loop the first
%argument passed to fn is an index 
%vector, and second and following arguments are the slices of each input
%according to that vector.
%
%Each input must have the same size in the dimensions specified. That is,
%you can say iterate([2], fn, ones(3, 4), zeros(5, 4)), because the
%iteration is over dimension 2 and both arrays have size 4 in dimension 2.
%
%If no list of dims is given, a linear index is used, like Python
%iterate().
%
%Wackiness: if the dims argument is given as a cell rather than simple
%array, then cell arrays are "stripped" if you index into singletons before
%passing to your loop function. (i.e. like cellfun rather than like
%arrayfun.) Since this will "strip" the first argument in the case of
%iterate({2}, fn, cell(1,4), cell(2,4)),
%but not in iterate({2}, fn, cell(2,4), cell(2,4)) this makes   
%it a little more dangerous, hence is NOT the default
%
%Example:
% >> iterate(@(x,y)disp({x y}), reshape(10:10:90,3,3))
%     [1]    [10]
%     [2]    [20]
%     [3]    [30]
%     [4]    [40]
%     [5]    [50]
%     [6]    [60]
%     [7]    [70]
%     [8]    [80]
%     [9]    [90]
%
% >> iterate([1], @(x,y)disp({x, y}), reshape(10:10:90,3,3))
%     [1]    [3x1 double]
%     [2]    [3x1 double]
%     [3]    [3x1 double]


    if isa(dims, 'function_handle')
        %one dimensional iteration. fill in the dims and use a linear
        %index.
        varargin = {fn varargin{:}};
        fn = dims;
        dims = {1};
        varargin = cellfun(@(x)x(:), varargin, 'UniformOutput', 0);
    end
    
    if iscell(dims)
        stripcell = 1;
        dims = cell2mat(dims);
    else
        stripcell = 0;
    end
    %each argument must be the same size in the dimensions being iterated
    %over.
    for i = 1:numel(varargin)
        for d = dims
            if size(varargin{1}, d) ~= size(varargin{i},d)
                error('iterate:argumentsNotSameSize', 'Input arguments to iterate must be the same size in the dimensions being iterated over.');
            end
        end
    end


    %permute each input to bring the dimensions of iteration to the
    %front.
    varargin = cellfun(@rearrange, varargin, 'UniformOutput', 0);
    function out = rearrange(in)
        sz = size(in);
        extradims = 1:max(ndims(in),max(dims));
        extradims([dims]) = [];
        if stripcell && all(sz(extradims) == 1) && iscell(in)
            strip = 1;
        else
            strip = 0;
        end
        out = permute(in, [dims extradims]);
        out = n2c(out, numel(dims)+1:numel(dims)+numel(extradims));
        out = cellfun(@(each)shiftdim(each, numel(dims)), out, 'UniformOutput',0);
        if strip
            out = cellfun(@(each)each{:}, out, 'UniformOutput', 0);
        end
    end

    %what makes ITERATE ITERATE is the index argument. Note it is a
    %collapsed index that includes only the slices taken from each dim. And
    %each argument has the iterated dimention collapsed out of it.
    %Here we create the index vectors to iterate over.
    ndgridargs = arrayfun(@(d)1:size(varargin{1}, d), 1:numel(dims), 'UniformOutput', 0);
    [indices{1:numel(dims)}] = ndg(ndgridargs{:});
    indices = cat(numel(dims)+1, indices{:});
    indices = reshape(n2c(permute(indices, [numel(dims)+1 1:numel(dims)]), 1), size(varargin{1}));
    
    %NOW....
    [varargout{1:nargout}] = cellfun(fn, indices, varargin{:});
end

function out = n2c(in, dims)
    %There is no reason why num2cell(x) ought to behave
    %differently from num2cell(x, []). The second argument to num2cell is a
    %list of dimensions to be concatenated together; the default behavior
    %of num2cell in absence of the second argument is not to concatenate
    %any dimensions together. Therefore you would think that num2cell(x) is
    %the same as num2cell(x, []), no?
    %
    %Instead, num2cell(x, []) produces an error. That means if you have a
    %function like the above iterate() that dynamically decides, based on
    %its input, which dimensions to concatenate together, than you must
    %have a special check for whether the answer is "concatenate no
    %dimensions together.
    if isempty(dims)
        %in a logical world this would not be necessary
        out = num2cell(in);
    else
        out = num2cell(in, dims);
    end
end

function varargout = ndg(varargin)
    %Doubleyou Tee F. You'd think that ndgrid, being named with ND like it
    %is, would work with problems of any dimensionality, that is to say in
    %cases with one or zero dimensions. MATLAB strikes again.
    switch nargin
        case 0
            varargout = {};
        case 1
            varargout = {varargin{1}(:)};
        otherwise
            [varargout{1:nargout}] = ndgrid(varargin{:});
    end
end