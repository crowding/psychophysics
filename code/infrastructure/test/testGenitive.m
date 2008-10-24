function this = testGenitive(varargin)
    
    persistent init__; %#ok
    this = inherit(TestCase(), autoobject(varargin{:}));
    
    function testBasicGenitive()
        its = Genitive();
        x = {'a' 'b' 'c' 'd' 'e' 'f'};
        assertEquals('e', subsref(x, its{5}));
    end
end