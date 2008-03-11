function dpkill(id)
% dpkill(id)
%
% Kill DP tasks specified by ID.
%
% ID must be numeric.

if ~isnumeric(id)
    error('ID must be numeric.');
end

for i=1:numel(id)
    info=pvm_kill(id(i));
    if info<0
        error(['Error while calling pvm_kill(',num2str(tid(i)),').']);
    end
end