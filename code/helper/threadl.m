function x = threadl(x, varargin)
% ersatz function threading form. Test my patience for @-signs and braces.
    varargin = reshape(varargin, 2, []);
    for i = varargin
        x = i{1}(x, i{2}{:});
    end
end
