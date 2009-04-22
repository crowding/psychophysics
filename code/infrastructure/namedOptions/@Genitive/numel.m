function n = numel(this, subs)
    %since we will return the struct and not actually perform a subscript
    %operation, the object, just return 1. 
    n = 1;
end