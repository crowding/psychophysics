function this = testClock2Filename
    this = public(...
        @testToName1,...
        @testToName2,...
        @testFromName1,...
        @testFromName2...
    );
    
    function testToName1
        assertEquals('DD05CO6', clock2filename([2006 8 1 11 12 6.2]));
    end


    function testToName2
        assertEquals('BPF6GJA', clock2filename([1980 11 25 20 09 42]));
    end

    function testFromName1
        assertEquals([2006 8 1 11 12 6], filename2clock('DD05CO6'));
    end

    function testFromName2
        assertEquals([1980 11 25 20 09 42], filename2clock('BPF6GJA'));
    end

end