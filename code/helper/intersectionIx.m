function mark = intersectionIx(strs1, strs2)

%returns a logical array marking the strings in strs1 that are contained in
%strs2. Much faster than using intersect() for this purpose.
mark = logical(zeros(size(strs1)));
for i = strs2(:)'
    mark(strcmp(i{:}, strs1)) = 1;
end

end