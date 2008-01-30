function varargout = e(thing, varargin)

if isa(thing, 'function_handle')
    [varargout{1:nargout}] = thing(varargin{:});
elseif isstruct(thing) && isfield(thing, 'e')
    [varargout{1:nargout}] = thing.e(varargin{:});
else
    varargout{1} = thing;
end