function this = testHandlers
    this = public(@testNotWritten);
    
    function testNotWritten
        fail('test suite not written');
    end
end