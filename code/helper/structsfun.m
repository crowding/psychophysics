function varargout = structsfun(f, varargin)
%STRUCTFUN only iterates over the fields of one structure?! How dumb.

fn = fieldnames(varargin{1});
varargin = cellaccum(@orderlike, varargin{1}, varargin, 'UniformOutput', 0) ;
varargin = cellfun(@struct2cell, varargin, 'UniformOutput', 0);

[varargout{1:nargout}] = cellfun(f, varargin{:}, 'UniformOutput', 0);
varargout = cellfun(@(x) cell2struct(x, fn), varargout, 'UniformOutput', 0);