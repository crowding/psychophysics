function this = StructArrayTest(varargin)
    persistent init__; %#ok
    this = inherit(TestCase(), autoobject(varargin{:}));

    function testToSOA
        soa = struct('foo', [1 2 3], 'bar', [4 5 6], 'baz', [7 8 9]);
        aos = struct('foo', {1 2 3}, 'bar', {4 5 6}, 'baz', {7 8 9});
        
        assertEquals(soa, aos2soa(aos));
    end

    function testToAOS
        soa = struct('foo', [1 2 3], 'bar', [4 5 6], 'baz', [7 8 9]);
        aos = struct('foo', {1 2 3}, 'bar', {4 5 6}, 'baz', {7 8 9});
        
        assertEquals(aos, soa2aos(soa));
    end
    
    function testNonMatchingSizes
        aos = struct('foo', {1 [2 2] 3}, 'bar', {4 5 6}, 'baz', {7 8 9});

        try
            aos2soa(aos);
            error('test:expectedError', 'expected an error');
        catch
            noop();
        end
    end

    function testCell2aos
        %note that the AOS has each entry wrapped in a singleton cell if
        %you want to do this....
        aos = struct('foo', {{1} {[2 2]} {3}}, 'bar', {4 5 6}, 'baz', {7 8 9});
        soa = struct('foo', {{1 [2 2] 3}}, 'bar', [4 5 6], 'baz', [7 8 9]);
        
        conv = soa2aos(soa);
        assertEquals(aos, conv);
    end

    function testCell2soa
        %note that the AOS has each entry wrapped in a singleton cell if
        %you want to do this. I will not get mixed up in auto-boxing ang
        %unboxing. It is the devil.
        aos = struct('foo', {{1} {[2 2]} {3}}, 'bar', {4 5 6}, 'baz', {7 8 9});
        soa = struct('foo', {{1 [2 2] 3}}, 'bar', [4 5 6], 'baz', [7 8 9]);
        
        conv = aos2soa(aos);
        assertEquals(soa, conv);
    end

    function testMultidim2aos
        aos = struct('foo', repmat({'a'}, [4 3 5]), 'bar', 'b', 'baz', num2cell(reshape(1:60, [4 3 5])));
        soa = struct('foo', repmat('a', [4 3 5]), 'bar', repmat('b', [4 3 5]), 'baz', reshape(1:60, [4 3 5]));
        
        conv = soa2aos(soa);
        assertEquals(aos, conv);
    end

    function testMultidim2soa
        aos = struct('foo', repmat({'a'}, [4 3 5]), 'bar', 'b', 'baz', num2cell(reshape(1:60, [4 3 5])));
        soa = struct('foo', repmat('a', [4 3 5]), 'bar', repmat('b', [4 3 5]), 'baz', reshape(1:60, [4 3 5]));
        
        conv = aos2soa(aos);
        assertEquals(soa, conv);
    end

    function testMultidimVectors2soa
        aos = struct('foo', repmat({'a'}, [1 1 5]), 'bar', 'b', 'baz', num2cell(reshape(1:5, [1 1 5])));
        soa = struct('foo', repmat('a', [1 1 5]), 'bar', repmat('b', [1 1 5]), 'baz', reshape(1:5, [1 1 5]));

        conv = aos2soa(aos);
        assertEquals(soa, conv);
    end

    function testMultidimVectors2aos
        aos = struct('foo', repmat({'a'}, [1 1 5]), 'bar', 'b', 'baz', num2cell(reshape(1:5, [1 1 5])));
        soa = struct('foo', repmat('a', [1 1 5]), 'bar', repmat('b', [1 1 5]), 'baz', reshape(1:5, [1 1 5]));
 
        conv = soa2aos(soa);
        assertEquals(aos, conv);
    end



end