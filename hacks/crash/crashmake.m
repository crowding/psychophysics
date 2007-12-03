function w = crashmake(t,u,v)
    w = evalin('caller', '@(x,y,z) {@()0, @()eps(0)}');
    w = w(0,0,0);
end