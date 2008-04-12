function num = numel(this, varargin)

%fuck if I know, here.
if iscell(varargin{1}) || isstruct(varargin{1})
    num = numel(varargin{1});
else
    num = 1;
end
