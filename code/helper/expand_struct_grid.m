function out = expand_struct_grid(A, B, combiner)
    if ~exist('combiner', 'var')
        combiner = @times;
    end
    fna = fieldnames(A);
    fnb = fieldnames(B);
    sa = size(A.(fna{1}),2);
    sb = size(B.(fnb{1}),2);
    fnu = intersect(fna, fnb);
    fna = setdiff(fna, fnu);
    fnb = setdiff(fnb, fnu);
    [ia, ib] = ndgrid(1:sa,1:sb);

    out = struct();
    for n = fna'
        x = A.(n{1});
        ss = substruct('()', repmat({':'}, 1, ndims(x)));
        ss.subs{2} = ia;
        out.(n{1}) = subsref(x, ss);
    end
    for n = fnb'
        x = B.(n{1});
        ss = substruct('()', repmat({':'}, 1, ndims(x)));
        ss.subs{2} = ib;
        out.(n{1}) = subsref(x, ss);
    end
    for n = fnu'
        x = A.(n{1});
        y = B.(n{1});
        sa = substruct('()', repmat({':'}, 1, ndims(x)));
        sa.subs{2} = ia;
        sb = substruct('()', repmat({':'}, 1, ndims(y)));
        sb.subs{2} = ib;
        out.(n{1}) = combiner(subsref(x, sa), subsref(y, sb));
    end
end