function this = testFromBytes(varargin)

    persistent init__;
    this = inherit...
        ( TestCase()...
        , BaseBytesTest()...
        , autoobject(varargin{:})...
        );
    
    function check(format, data, bytes, varargin)
        %assertEquals asserts data types too; we just want to assert data
        assertIsEqual ...
            ( data ...
            , frombytes(bytes, format, varargin{:}) ...
            );
    end

    function testEnumTranslation()
        %test that we can disregard enum translation if we want.
        
        format = struct('enum_', uint16(0), 'optionA', 1, 'optionB', 2, 'optionC', 3);
        formatted = 2;
        bytes = uint8([0 2]);
        
        tested = frombytes(bytes, format, 'enum', 0);
        assertIsEqual(formatted, tested);
    end

end