function results = runTests(suite)
    %a 'suite' here is a struct containing a bunch of function handles that
    %can be run; the handles either return successfully or throw errors.
    results = structfun(@runTest, suite);
    
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
            disp(['??? ' result.details.identifier ': ' result.details.message]);
            arrayfun(@traceframe, result.details.stack);
            disp('');
        end
    end

    function traceframe(frame)
        %print the offending stack trace.
        %The error URL is undocumented as far as I know.
        disp(sprintf('Error in ==> <a href="error:%s,%d,1">%s at %d</a>',...
            frame.file, frame.line, frame.name, frame.line));
        %actual code may be too busy...
        %dbtype(frame.file, num2str(frame.line));
        %TODO: filter the stack trace so that it stops in the test
        %framework
    end
    
    function result = runTest(testfn)
        testfninfo = functions(testfn);
        testname = testfninfo.function;
        
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
