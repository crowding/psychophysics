function this = testDataDumper
    this = inherit(TestCase(), public(...
        @setUp...
        ,@testStruct...
        ,@testDeepStruct...
        ,@testProperties...
        ,@testBasicObject...
        ,@testFancyObject...
        ,@testPropertyObject...
        ));
    
    %I have realized that by this point i think MATLAB is horrible enough
    %that I don't want to be locked into a language that has to read its
    %data files. So I will dump out my experiment data to text (this has
    %the happy side effect that I can dump my experiment data out to the
    %Eyelink and be incorporated in the logs.)
    %
    %This test suite defines the dumping format. Basically 'dump' takes an
    %object and a handle to a printf-like function, and outputs a bunch of
    %statements that can be eval()ed to recreate the dumped data. Note the
    %printf thing won't end its statements with newlines.
    %
    %this is not yet general purpose. Embedded newlines in strings,
    %multidimensional arrays, cell arrays, objects constructed by nested 
    %functions, non-double arrays, and nonscalar arrays of structs are
    %all unsupported. 
    
    output = {};
    
    function setUp
        output = {};
    end

    function printer(varargin)
        output{end+1} = sprintf(varargin{:});
    end

    function testStruct
        a = struct('a', 1, 'b', [1 2 3], 'c', 'hello');
        dump(a, @printer);
        
        assertEquals({'a.a = 1;', 'a.b = [1 2 3];', 'a.c = sprintf(''hello'');'}, output);
    end

    function testDeepStruct
        a = struct('a', 1, 'b', struct('a', 1, 'b', 2));
        dump(a, @printer);
        assertEquals({'a.a = 1;', 'a.b.a = 1;', 'a.b.b = 2;'}, output);
    end

    function testProperties
        a = properties('x', 1, 'y', 2);
        dump(a, @printer);
        assertEquals({'a.x = 1;', 'a.y = 2;', 'a = testDataDumper/testProperties(a);'}, output);
    end

    function testBasicObject
        %the 'constructor' is captured and called
        a = inherit(properties('x', 1, 'y', 2)); %it gets a version__ attribute

        dump(a, @printer);
        
        %This nested function name can't actually be evaled, but demonstrates the format and
        %expectation that constructors take struct initializer arguments
        %for their properties
        assertEquals({'a.x = 1;', 'a.y = 2;', 'a = testDataDumper/testBasicObject(a);'}, output);
    end

    function testFancyObject
        %the 'constructor' is captured and called
        a = Object(inherit(properties('x', 1, 'y', 2)));
        
        dump(a, @printer);
        assertEquals({'a.x = 1;', 'a.y = 2;', 'a = testDataDumper/testFancyObject(a);'}, output);
    end

    function testPropertyObject
        aa = PropertyObject();
        a = aa;
        dump(a, @printer);
        assertEquals('a.center = [0 0 0];', output{1});
        
        %smart string escaping!
        a = struct();
        eval(output{2});
        assertEquals(aa.svn, a.svn);
        
        assertEquals('a = PropertyObject(a);', output{3});
    end

end