function varargout = mat2args(mat)
    x = num2cell(mat);
    [varargout{1:nargout}] = x{:};
end