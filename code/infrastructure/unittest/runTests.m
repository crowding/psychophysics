function results = runTests(suite)
    %a 'suite' here is a struct containing a bunch of function handles that
    %can be run; the handles either return successfully or throw errors.
    
    %gather all methods beginning with 'test'
    testnames = fieldnames(suite);
    testnames = testnames(strmatch('test', testnames));
    methods = cellfun(@(name) suite.(name), testnames, 'UniformOutput', 0);
    
    results = cellfun(@runTest, testnames, methods);
    
    if (nargout == 0)
        %print out the results
        arrayfun(@showtest, results);
        
        %tally the results
        npass = sum(arrayfun(@(x) strcmp('PASS', x.result), results));
        nfail = sum(arrayfun(@(x) strcmp('FAIL', x.result), results));
        nerr = sum(arrayfun(@(x) strcmp('ERR', x.result), results));
        
        disp(sprintf('%d tests: %d passed, %d failed, %d errors',...
            numel(results), npass, nfail, nerr));
    end
    
    function showtest(result)
        disp(sprintf('%70s: %4s', result.test, result.result));
        disp([])
        if ~strcmp(result.result, 'PASS')
            stacktrace(result.details);
        end
    end
    
    function result = runTest(testname, testfn)
        
        result = struct('test', testname, 'result', [], 'details', []);
        
        try
            testfn();
            result.result = 'PASS';
        catch
            handlers(...
                'assert:', @assert, ...
                '', @default);
        end
        function assert(err)
            result.result = 'FAIL';
            result.details = err;
        end
        function default(err)
            result.result = 'ERR';
            result.details = err;
        end
    end
end
