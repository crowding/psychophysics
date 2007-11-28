function this = TestCase(varargin)

    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    function setUp()
    end

    function tearDown()
    end

    function initializer = init()
        initializer = @i;
        function [r, params] = i(params)
            this.setUp();
            r = this.tearDown;
        end
    end
end
