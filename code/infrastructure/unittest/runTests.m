function results = runTests(varargin)
%a 'suite' here is a struct containing a bunch of function handles that
%can be run; the handles either return successfully or throw errors.

%You can provide strings cell arrays of strings to specify which tests to
%run. If none are specified, all tests beginning with 'test' are run.

    testsuite = struct();
    tests = {};

    results = struct('testobj', {}, 'test', {}, 'result', {}, 'details', {});

    for i = {varargin{:} struct()}
        if isstruct(i{1})
            %run the previous
            if isempty(tests)
                tests = fieldnames(testsuite);
                tests = tests(strmatch('test', tests));
            end
            results = cat(1, results, doRunTests(testsuite, tests));

            %prepare the next
            testsuite = i{1};
            tests = {};
        elseif ischar(i{1})
            tests = cat(1, tests, {i{1}});
        elseif iscell(i{1});
            tests = cat(1, tests, {i{1}{:}}');
        end
    end

    if (nargout == 0)
        showSummary(results)
    end
end

function showSummary(results)
        %tally the results
        npass = sum(arrayfun(@(x) strcmp('PASS', x.result), results));
        nfail = sum(arrayfun(@(x) strcmp('FAIL', x.result), results));
        nerr = sum(arrayfun(@(x) strcmp('ERR', x.result), results));

        fprintf('%d tests: %d passed, %d failed, %d errors\n(%s) (%s)\n'...
            , numel(results), npass, nfail, nerr...
            , linkfunction(@()runAll(results), 'rerun all')...
            , linkfunction(@()runFailures(results), 'rerun failures'));
end

function runAll(results)
    results = arrayfun(@(t)showtest(runTest(t.testobj, t.test)), results);
    
    showSummary(results);
end

function runFailures(results)
    which = ~strcmp('PASS', {results.result});
    results(which) = arrayfun(@(t)showtest(runTest(t.testobj, t.test)), results(which));
    
    showSummary(results);
end

function results = doRunTests(testobj, testnames)
    results = [];
    for name = {testnames{:}}
        results = [results runTest(testobj, name{:})];
        showtest(results(end));
    end
end

function result = showtest(result, trace)
    if (nargin < 2)
        trace = 0;
    end
    resultstr = result.result;
    if ~strcmp(resultstr, 'PASS')
        resultstr = linkfunction(@()showtest(result,1), resultstr);
    end

    str = sprintf('%70s: %4s\n', result.test, resultstr);
    %now link the str...
    x = min(strfind(str, ':'));
    start = x - length(result.test);
    str = [str(1:start-1) linkfunction(@()doRunTests(result.testobj, {result.test}), result.test) str(x:end)];
    fprintf('%s', str);

    if ~strcmp(result.result, 'PASS') && trace
        stacktrace(result.details);
    end
end

function result = runTest(obj, testname)
    testfn = obj.(testname);
    
    result = struct('testobj', obj, 'test', testname, 'result', [], 'details', []);

    try
        %note that the param struct is not passed into the test function
        %(capture it in your init if needed
        require(obj.init(), @(x)testfn());
        result.result = 'PASS';
    catch
        handlers...
            ( 'MATLAB:assert:', @assert ...
            , 'assert:', @assert ...
            , '', @default ...
            );
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