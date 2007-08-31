function n = numbytes(varargin)
%returns the number of bytes that would be produced by calling tobytes()
%on the arguments.

n = 0;
for i = 1:nargin
    b = varargin{i}; %#ok
    s = whos('b');
    n = n + s.bytes;
end