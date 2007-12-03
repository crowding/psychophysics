function f = bpl1()
    x = 4;
    system(sprintf('mv %s.m bpl1_one.m', mfilename));
    system(sprintf('mv bpl1_two.m %s.m', mfilename));
    rehash;
    f = @boo;
end