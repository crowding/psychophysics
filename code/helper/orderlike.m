function o = orderlike(template, struct)
% function orderlike(template, struct)
%
% rebuild a struct so that its fields come in the same ORDER as another
% struct template.
% 
% matlab lameness %374:
% the order of fields in a struct matters when initializing an object,
% where it should not matter ANYWHERE!

for i = makerow(fieldnames(template))
    o.(i{1}) = struct.(i{1});
end