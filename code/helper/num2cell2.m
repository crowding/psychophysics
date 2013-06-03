function C = num2cell2(A, dims)
    %like num2cell but in the inverse sense
    idims = setdiff(1:ndims(A), dims);
    C = num2cell(A, idims);
end