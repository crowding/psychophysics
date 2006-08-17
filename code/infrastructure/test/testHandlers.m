function this = testHandlers
    this = inherit(TestCase, public(@testNotWritten));
    
    function testNotWritten
        fail('test suite not written');
    end
end