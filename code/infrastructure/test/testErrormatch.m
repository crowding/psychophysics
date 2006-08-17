function this = testErrormatch
    this = inherit(TestCase(), public(@testNotWritten));
    
    function testNotWritten
        fail('test suite not written');
    end
end