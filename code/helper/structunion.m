function u = structunion(varargin)
    %builds a structure that is the unino of the 
    structargs = {};
    for i = varargin
        s = i{1};
        f = fieldnames(s);
        v = struct2cell(s);
        sz = num2cell(size(v));
        v = shiftdim(v, 1);
        v = mat2cell(v, sz{2:end}, ones(sz{1}, 1));
        sa = {f{:}; v{:}};
        structargs = cat(2, structargs, sa(:)');
    end
    u = struct(structargs{:});
end