function evalf(varargin)
    expr = sprintf(varargin{:});
    disp(expr);
    evalin('base', expr);
end