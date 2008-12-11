function varargout = unwrap(varargin)
    for i = 1:nargin
        if isa(varargin{i}, 'Obj')
            varargout{i} = varargin{i}.wrapped;
        else
            varargout{i} = varargin{i};
        end
    end
end