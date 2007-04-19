function results = runTests(varargin)
%a 'suite' here is a struct containing a bunch of function handles that
%can be run; the handles either return successfully or throw errors.
results = cellfun(@doRunTests, varargin, 'UniformOutput', 0);

results = cat(1, results{:});

if (nargout == 0)

    %tally the results
    npass = sum(arrayfun(@(x) strcmp('PASS', x.result), results));
    nfail = sum(arrayfun(@(x) strcmp('FAIL', x.result), results));
    nerr = sum(arrayfun(@(x) strcmp('ERR', x.result), results));

    disp(sprintf('%d tests: %d passed, %d failed, %d errors',...
        numel(results), npass, nfail, nerr));
end

    function results = doRunTests(obj)
        %gather all methods beginning with 'test'
        testnames = fieldnames(obj);
        testnames = testnames(strmatch('test', testnames));

        results = cellfun(@(test)showtest(runTest(obj, test)), testnames);

        function result = showtest(result)
            disp(sprintf('%70s: %4s', result.test, result.result));
            disp([])
            if ~strcmp(result.result, 'PASS')
                stacktrace(result.details);
            end
        end

        function result = runTest(obj, testname)
            testfn = obj.(testname);

            result = struct('test', testname, 'result', [], 'details', []);

            try
                %note that the param struct is not passed into the test function
                %(capture it in your init if needed
                require(obj.init(), @(x)testfn); 
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
end