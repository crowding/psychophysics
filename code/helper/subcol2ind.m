function ind = matsub2ind(sz, sub)
    %convert column-wise subscripts into indices
    sub = num2cell(sub, 2:ndims(sub));
    ind = sub2ind(sz, sub{:});
end