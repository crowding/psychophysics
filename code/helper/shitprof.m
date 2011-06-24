function out = shitprof(arg)
persistent l;
persistent n;
if isempty(l)
    l = {};
    n = 0;
end

switch(arg)
    case 'clear'
        x = {};
        n = 0;
    case 'readout'
        out = shitprof_readout(l,n);
    otherwise
        l = {arg, GetSecs(), l};
        n = n + 1;
end