function this = TestCase
    this = public(@init, @setUp, @tearDown);
    
    function setUp
    end

    function tearDown
    end

    function initializer = init()
        initializer = @i;
        function [r, params] = i(params)
            this.setUp();
            r = this.tearDown;
        end
    end
end
