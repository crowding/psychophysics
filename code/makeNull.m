function s = makeNull(s)
%fills a struct's fields with empty arrays.

for i = fieldnames(s)'
    s.(i{:}) = [];
end