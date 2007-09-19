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
if iscell(mat)
    m = mat;
    for i = 1:numel(m)
        if nargin > 1
            m{i} = smallmat2str(m{i}, c);
        else
            m{i} = smallmat2str(m{i});
        end
    end
else

    if numel(mat) ~= 1
        m = sprintf('%.15g ', mat');
        %FIXME: weird-zero-size-arrays

        ncols = size(mat, 2);
        if(size(mat, 1) > 1)
            spaceix = find(m == ' ');
            m(spaceix(ncols:ncols:end-1)) = ';';
        end

        if nargin > 1 && ~strcmp(class(mat), 'double')
            m(end) = ']';
            m = [class(mat), '([', m, ')'];
        else
            m = ['[', m];
            m(end) = ']';
        end
    else
        m = sprintf('%.15g', mat');
        if nargin > 1
            m = [class(mat), '(', m, ')'];
        end
    end
end