function varargout = getOutput(outputs, fn, varargin)

[result{1:max(outputs)}] = fn(varargin{:});
[varargout{1:numel(outputs)}] = result{outputs};