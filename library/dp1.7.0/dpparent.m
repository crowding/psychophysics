function id=dpparent
% id=dpparent
%
% Get ID of parent task.
% If task was not spawned, ID is an empty array.

id=pvm_parent;
if id==-23
    id=[];
end