function [varargout] = argfun(fn, varargin)
%function [varargout] = argfun(fn, varargin)
% Useful for statements like:
% [structure.field] = argfun(@(X)X+2, structure.field)

c = cellfun(fn, varargin, 'UniformOutput', 0);
[varargout{1:nargout}] = c{:};