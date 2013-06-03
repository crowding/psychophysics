function out = structcbind(varargin)
% a wacky data manupulation that is mostly of help to build parameters
% for my motion stimuli.  Given a number of structs, cat their values
% together field-by-field.  Any missing fields are carried rightwards
% or leftwards.  Before catting values, number of columns in each
% struct are normalized using vector recycling.

    eachnames = cellfun(@fieldnames, varargin, 'UniformOutput', 0);
    allnames = cellreduce(@union, eachnames{1}, eachnames);

    %carry missing field values forwards
    varargin = cellaccum(@carry_fields, varargin{1}, varargin, 'UniformOutput', 0);
    function b = carry_fields(a, b)
        for f = setdiff(fieldnames(a), fieldnames(b))'
            b.(f{1}) = a.(f{1});
        end
    end

    %then backwards
    varargin(end:-1:1) = varargin;
    varargin = cellaccum(@carry_fields, varargin{1}, varargin, 'UniformOutput', 0);
    varargin(end:-1:1) = varargin;

    varargin = cellfun(@normalize_cols, varargin, 'UniformOutput', 0);
    function s = normalize_cols(s)
        ncol = max(structfun(@(x) size(x,2), s(:)));

        s = structfun(@recycle, s, 'UniformOutput', 0);
        function x = recycle(x)
            nscol = size(x, 2);
            if mod(ncol, nscol) ~= 0
                error('Vector length not an even multiple of larger length');
            else
                x = num2cell2(x, 2);
                x = x(mod(0:ncol-1, nscol)+1);
                x = cat(2, x{:});
            end
        end
    end

    out = structsfun(@horzcat, varargin{:});
end
