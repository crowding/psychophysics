function is = flagged(struct, name)
%function is = flagged(struct, name)
%returns true if the named field is present and true.
is = isfield(struct, name) && struct.(name);