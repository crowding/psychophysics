function testConsList
%demonstrating that cell arrays mimicking cons lists can be reasonably
%efficient for matlab data structures...

    n = 10000;
    profile on;
    a = buildConsList(n);
    b = buildCellArray(n);
    c = fillCellArray(n);
    
    whos
    
    a = keepEvenCons(a);
    b = keepEvenList(b);
    c = keepEvenVectorized(c);
    profile viewer;
    whos
end

function c = buildConsList(n)
    c = [];
    for i = 1:n
        c = {i, c};
    end
end

function c = buildCellArray(n)
    c = {};
    for i = 1:n
        c{i} = n;
    end
end

function c = fillCellArray(n)
    c = cell(1, n);
        for i = 1:n
        c{i} = n;
    end
end

function b = keepEvenCons(a)
    b = [];
    while iscell(a)
        [val, a] = a{:};
        if mod(val,2) == 0
            b = {val, b};
        end
    end
end

function a = keepEvenList(a)
    for i = numel(a):-1:1
        if mod(a{i}, 2) == 0
            a(i) = [];
        end
    end
end

function a = keepEvenVectorized(a)
    dropix = cellfun(@(x) mod(x, 2) ~= 0, a);
    a(dropix) = [];
end