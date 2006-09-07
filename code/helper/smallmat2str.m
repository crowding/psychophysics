function m = smallmat2str(mat, c)

%bare bones and much faster alternative to mat2str.

%this won't accurately represent int64s or uint64. Listen to this
%screamer of a line from the matlab documentation!
%
%"NOTE: The range of values that can be passed to UINT64 from the command
%prompt or from an M-file function without loss of precision is 0 to
%2^53, inclusive. When reading values from a MAT-file, UINT64 correctly
%represents the full range 0 to (2^64)-1."
%
%What the hell kind of language has data types that can't possibly be
%filled in from source literals, even in principle?
%

m = sprintf('%.15g ', mat');
spaceix = find(m == ' ');

if numel(mat) ~= 1
    %FIXME: weird-zero-size-arrays

    ncols = size(mat, 2);
    m(spaceix(ncols:ncols:end-1)) = ';';

    if nargin > 1
        m = [class(mat), '([', m, '])'];
    else
        m = ['[', m, ']'];
    end
else
    if nargin > 1
        m = [class(mat), '(', m, ')'];
    else
        %m = m(1:end-1);
    end
end