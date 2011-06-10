function sub = ind2subcol(sz, index)
    %convert indices into column-wise subscripts.
    [sub{1:size(index, 1)}] = sub2ind(sz, index);
    sub = reshape(cat(ndims(index) + 1, sub{:}), [], numel(size))';
end