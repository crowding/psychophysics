function [fout, accessor] = reassignableFunction(fin)
    fout = @invoke;
    accessor = @access;

    function varargout = invoke(varargin)
        %how much time...
        [varargout{1:nargout}] = fin(varargin{:});
    end

    function f = access(f)
        if (nargin == 0)
            f = fin;
        else
            fin = f;
        end
    end
end