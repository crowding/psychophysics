function this = testNunion

this = public(...
    @testSingleArg...
    ,@testSingleArgIndex...
    ,@testDoubleArg...
    ,@testDoubleArgIndex...
    );

    function testSingleArg
        assertEquals([1 2 3 4]', nunion([1 4 2 3 1 4 2 3 1 4]));
        assertEquals({'bar' 'baz' 'qux'}', nunion({'bar' 'baz' 'bar' 'qux' 'bar' 'qux' 'qux' 'qux'}));
    end

    function testSingleArgIndex
        [a, i] = nunion([1 4 2 3 1 4 2 3 1 4]);
        assertEquals([9 7 8 10]', i);
        [a, i] = nunion({'bar' 'baz' 'bar' 'qux' 'bar' 'qux' 'qux' 'qux'});
        assertEquals([5 2 8]', i);

    end

    function testDoubleArg
        assertEquals([1 2 3 4]', nunion([1 3 1 2 3 2 3], [2 4 3 2 4 3]));
        assertEquals({'bar' 'baz' 'foo'}', ...
            nunion({'bar' 'baz' 'bar' 'baz'}', {'foo' 'baz' 'foo' 'baz'}));
    end

    function testDoubleArgIndex
        [a i1 i2] = nunion([1 3 1 2 3 2 3], [2 4 3 2 4 3]);
        assertEquals([3], i1);
        assertEquals([4 6 5]', i2);
        
        [a i1 i2] = nunion({'bar' 'baz' 'bar' 'baz'}, {'foo' 'baz' 'foo' 'baz'});
        assertEquals([3], i1);
        assertEquals([4 3]', i2);
    end


end