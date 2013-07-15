function x = threadr(x, varargin)
% ersatz function threading form. Test my patience for @-signs and braces?
    varargin = reshape(varargin, 2, []);
    for i = varargin
        x = i{1}(i{2}{:}, x);
    end
 end