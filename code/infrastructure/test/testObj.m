function this = testObj(varargin)

this = inherit(TestCase, autoobject(varargin{:}));

    function this = fooObject(varargin)
        propA = 1;
        propB = 2;
        
        persistent init__;
        this = autoobject(varargin{:});
        function x = sum
            x = propA + propB;
        end
    end

    function testIsStruct
        o = Obj(fooObject());
        assert(isstruct(o))
    end

    function testFieldNames
        o = Obj(fooObject());
        assertEquals({'propA'; 'propB'}, fieldnames(o));
    end

    function testSubsrefParen
        o = Obj([1 2 3]);
        assertEquals(3, o(3));
    end

    function testSubsrefBrace
        o = Obj({1 2 3});
        assertEquals(3, o{3});
    end

    function testSubsrefDot
        o = Obj(struct('a', 1));
        assertEquals(1, o.a);
    end

    function testSubsrefBasic
        o = Obj(fooObject('propA', 2));
        assertEquals(2, o.propA);
    end

    function testSubsrefArrays
        o = Obj(fooObject('propB', [1 2 3]));
        assertEquals(3, o.propB(3));
    end

    function testSubsrefCells
        o = Obj(fooObject('propB', {1 2 3}));
        assertEquals(3, o.propB{3});
    end

    function testSubsrefStructs
        o = Obj(fooObject('propA', struct('a', 1, 'b', 2)));
        assertEquals(2, o.propA.b);
    end

    function testSubsrefObjects
        o = Obj(fooObject('propB', fooObject('propA', 'q')));
        assertEquals('q', o.propB.propA)
    end

    function testSubsrefMethodCall
        o = Obj(fooObject('propA', fooObject('propA', 2, 'propB', 2)));
        assertEquals(4, o.propA.sum());
    end

    function testSubsrefCellContents
        o = Obj({1 2 3 4});
        [x, y] = o{[3 2]};
        assertEquals(3, x);
        assertEquals(2, y);
    end

    function testSubsrefArglist
        o = Obj({1 2 3 4});
        [x, y] = deal(o{[3 2]});
        assertEquals(3, x);
        assertEquals(2, y);
    end

    function testSubsrefStructArray
        o = Obj(struct('a', {1 2 3}));
        [x, y, z] = o.a;
        assertEquals(1, x);
        assertEquals(2, y);
        assertEquals(3, z);
    end

    function testSubsrefStructArglist
        o = Obj(struct('a', {1 2 3}));
        [x, y, z] = deal(o.a);
        assertEquals(1, x);
        assertEquals(2, y);
        assertEquals(3, z);
    end

    function testMethodCall
        o = Obj(fooObject('propA', 1, 'propB', 2));
        assertEquals(3, o.sum());
    end



    function testGetStructNoArgs
        %implementation of "get" for structs
        a = Obj(struct('a', 1, 'b', 3));
        assertEquals(get(a), struct('a', 1, 'b', 3));
    end

    function testGetObjectNoArgs
        a = Obj(fooObject('propA', 1, 'propB', 8));
        assertEquals(get(a), struct('propA', 1, 'propB', 8));
    end

    function testGetOldObjectNoArgs
        b = timer();
        a = Obj(b);
        assertEquals(get(b), get(a));
    end

    function testSetStructNoArgs
        %test implementation of set...
        b = Obj(struct('a', 1, 'b', 2));
        assertEquals(struct('a', {{}}, 'b', {{}}), set(b));
    end

    function testSetObjectNoArgs
        %implementation of set...
        b = Obj(fooObject('propA', 1, 'propB', 2));
        assertEquals(struct('propA', {{}}, 'propB', {{}}), set(b));
    end

    function testSetOldObjectNoArgs
        %implementation of set with an oldschool object
        x = Obj(timer());
        assertEquals(set(timer()), set(x));
    end



    function testSubsasgnParen
        o = Obj([1 2 3]);
        o(3) = 12;
        assertEquals(12, o(3));
    end

    function testSubsasgnBrace
        o = Obj({1 2 3});
        o{3} = 'foo';
        assertEquals('foo', o{3});
    end

    function testSubsasgnDot
        o = Obj(struct('a', 1));
        o.a = 3;
        assertEquals(3, o.a);
    end

    function testSubsasgnBasic
        o = Obj(fooObject('propA', 2));
        o.propA = 14;
        assertEquals(14, o.propA);
    end

    function testSubsasgnArrays
        o = Obj(fooObject('propB', [1 2 3]));
        o.propB(3) = 21;
        assertEquals(21, o.propB(3));
    end

    function testSubsasgnCells
        o = Obj(fooObject('propB', {1 2 3}));
        o.propB{3} = 'foo';
        assertEquals('foo', o.propB{3});
    end

    function testSubsasgnStructs
        o = Obj(fooObject('propA', struct('a', 1, 'b', 2)));
        o.propA.b = 41;
        assertEquals(41, o.propA.b);
    end

    function testSubsasgnObjects
        o = Obj(fooObject('propB', fooObject('propA', 'q')));
        o.propB.propA = 'r';
        assertEquals('r', o.propB.propA)
    end

    function testSubsasgnCellContents
        o = Obj({1 2 3 4});
        [o{[3, 2]}] = deal(45, 21);
        [x, y] = o{[3 2]};
        assertEquals(45, x);
        assertEquals(21, y);
    end

    function testSubsasgnStructArray
        %FIXME: this won't work, matlab bug.
        o = Obj(struct('a', {1 2 3}));
        x = {11, 22, 33};

        %this doesn't work, matlab bug in assignment?
        [o.a] = deal(11, 22, 33);
        [x, y, z] = o.a;
        assertEquals(11, x);
        assertEquals(22, y);
        assertEquals(33, z);
    end

    function testSubsasgnScalarExpansion
        o = Obj(zeros(5));
        o(2:4, 2:4) = 3;
        assertEquals(o(2:4, 2:4), zeros(3) + 3);
    end

    function testSubsasgnDeletion
        o = Obj(zeros(10, 1));
        o(2:9) = [];
        assertEquals(2, numel(o));
    end
end