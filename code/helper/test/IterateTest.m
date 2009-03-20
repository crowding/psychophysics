function this = iterateTest(varargin)
    % a test for the potentially useful ITERATE function.

    persistent init__;
    this = inherit(TestCase(), autoobject(varargin{:}));
    
    x = {};
    y = {};
    z = {};
    
    function seq(i,a,b)
        x{end+1} = i;
        y{end+1} = a;
        z{end+1} = b;
    end

    function cl()
        x = {};
        y = {};
        z = {};
    end

    function testSimple()
        cl();
        iterate(@seq, 2:2:20, 3:3:30)
        assertEquals({1,2,3,4,5,6,7,8,9,10}, x);
        assertEquals({2,4,6,8,10,12,14,16,18,20}, y);
        assertEquals({3,6,9,12,15,18,21,24,27,30}, z);
    end

    function testOneDimension()
        cl();
        iterate([2], @seq, 2:2:20, 3:3:30);
        assertEquals({1,2,3,4,5,6,7,8,9,10}, x);
        assertEquals({2,4,6,8,10,12,14,16,18,20}, y);
        assertEquals({3,6,9,12,15,18,21,24,27,30}, z);
    end

    function testOtherDimension()
        cl();
        iterate([1], @seq, 2:2:20, 3:3:30);
        assertEquals({[1]}, x);
        assertEquals({[2;4;6;8;10;12;14;16;18;20]}, y);
        assertEquals({[3;6;9;12;15;18;21;24;27;30]}, z);
    end

    function testSlices()
        cl();
        iterate([1], @seq, (3:3:9)', reshape(1:9, 3,3));
        assertEquals({1 2 3}, x);
        assertEquals({3,6,9}, y);
        assertEquals({[1;4;7],[2;5;8],[3;6;9]}, z);
    end

    function testMultiDim
        cl();
        iterate([1 2], @seq, reshape(1:9, 3,3), reshape(2:2:18,3,3));
        assertEquals({[1;1],[2;1],[3;1],[1;2],[2;2],[3;2],[1;3],[2;3],[3;3]}, x);
        assertEquals({1,2,3,4,5,6,7,8,9}, y);
        assertEquals({2,4,6,8,10,12,14,16,18}, z);
    end

    function testSwappedDim
        cl();
        iterate([2 1], @seq, reshape(1:9, 3,3), reshape(2:2:18,3,3));
        assertEquals({[1;1],[2;1],[3;1],[1;2],[2;2],[3;2],[1;3],[2;3],[3;3]}, x);
        assertEquals({1,4,7,2,5,8,3,6,9}, y);
        assertEquals({2,8,14,4,10,16,6,12,18}, z);
    end

    function testStripping
        cl();
        iterate({1}, @seq, num2cell((3:3:9)'), num2cell(reshape(1:9, 3,3)));
        assertEquals({1 2 3}, x);
        assertEquals({3,6,9}, y);
        assertEquals({{1;4;7},{2;5;8},{3;6;9}}, z);
    end

    function testNoStripping
        cl();
        iterate([1], @seq, num2cell((3:3:9)'), num2cell(reshape(1:9, 3,3)));
        assertEquals({1 2 3}, x);
        assertEquals({{3},{6},{9}}, y);
        assertEquals({{1;4;7},{2;5;8},{3;6;9}}, z);
    end


end