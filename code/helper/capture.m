function varargout = capture(varargin)

persistent captured;

if nargin >= 1
    captured = varargin;
    [varargout{1:nargin}] = captured{:};
else
    [varargout{1:numel(captured)}] = captured{:};
end