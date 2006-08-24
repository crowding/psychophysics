function this = testNamedArgs()

this = inherit(...
      TestCase()...
    , public(...
          @testCollectNames...
        , @testNameOverStructs...
        , @testStructOverNames...
        , @testStructOverStruct...
        , @testSubstructs...
        , @testOddArgs...
        , @testBadArgs...
        , @testStructArray...
        ));
    
    function testCollectNames()
        a = namedargs('val1', 1, 'val2', 2);
        assertEquals(a, struct('val1', 1, 'val2', 2));
    end

    function testNameOverStructs()
        s = struct('a', 1, 'b', 3);
        args = namedargs(s, 'b', 2);
        assertEquals(struct('a', 1, 'b', 2), args);
    end

    function testStructOverNames()
        s = struct('a', 101, 'b', 102);
        args = namedargs('a', 1, 'c', 3, s);
        assertEquals(struct('a', 101, 'b', 102, 'c', 3), args);
    end

    function testStructOverStruct()
        s1 = struct('a', 101, 'b', 102);
        s2 = struct('b', 201, 'c', 202);
        args = namedargs(s1, s2);
        
        assertEquals(struct('a', 101, 'b', 201, 'c', 202), args);
    end

    function testSubstructs
        s = struct('a', struct('x', 1), 'b', struct('y', 1), 'c', struct('z', 3));
        args = namedargs(...
            'c', struct('z', 2, 'zz', 1), ...
            s, ...
            'a', struct('y', 2), ...
            struct('b', struct('y', 3)));
        
        assertEquals(...
            struct(...
                'a', struct('x', 1, 'y', 2),...
                'b', struct('y', 3),...
                'c', struct('z', 3, 'zz', 1)),...
            args);
    end

    function testOddArgs
        try
            a = namedargs(struct('a', 1), 'a');
            fail('expected error');
        catch
            assertLastError('namedargs:');
        end
    end

    function testBadArgs
        try
            a = namedargs('a', 1, {1, 2, 3});
            fail('expected error');
        catch
            assertLastError('namedargs:');
        end
    end

    function testStructArray
        try
            a = namedargs('a', 1, struct('b', {1, 2, 3}));
            fail('expected error');
        catch
            assertLastError('namedargs:');
        end
    end
end
            