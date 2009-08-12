function varargout = fif(cond, fiftrue, fiffalse, varargin)
%function varargout = fif(cond, fiftrue, fiffalse, varargin)
%functional form of if -- invokes first function if cond is true, second if
%false, passing extra arguments on.

if cond
    [varargout{1:nargout}] = fiftrue(varargin{:});
elseif nargin > 2 && isa(fiffalse, 'function_handle')
    [varargout{1:nargout}] = fiffalse(varargin{:});
end