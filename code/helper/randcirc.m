function x = randcirc(varargin)
%generates a random vector of the requested size on the unit sphere.
%If asked to generate a matrix, each column lies on the unit sphere.
    x = randn(varargin{:});
    if isvector(x)
        x = x / norm(x);
    else
        n = sqrt(sum(x.^2, 1));
        s = num2cell(size(x));
        x = x ./ repmat(n, size(x, 1), 1);
    end
end