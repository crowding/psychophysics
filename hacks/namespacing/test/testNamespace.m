function testNamespace
    runTests(mfilename);
    %replace with testSuite(mfilename) when
    %testSuite exists

    function setup
        return
        
    function teardown
        return
        
    function testNotUsing
        assertEquals(which('wbdfibhr'), '', ...
            'function named wbdfibhr exists);
        assertEquals(0, exist('NamespacedFunctions.wbdfibhr'), ... 
            'namespacedFunctions.foo exists');
        assertEquals(0, exist('NamespacedFunctions'), ...
            'namespacedFunctions exists');

    function testNotOverridingBuiltin
        assertEquals(5, exist('plus'), ...
            'exist plus not a builtin');
        assertTrue(strfind(which('plus'), 'built-in'), ...
            'which plus not a builtin');
        
    function testVariableAssigned
        assertEquals(0, exist('NamespacedFunctions'));
        using NamespacedFunctions;
        assertEquals(
        
    function testFunctionUsable
        try
            namespacedFunctions.wbdfibhr(4);
            fail('should not be able to call wbdfibhr');
        catch
            %expected
            assertTrue( ...
                strcmp('MATLAB:UndefinedFunction', lasterror.identifier), ...
                ['unexpected error ' lasterror.identifier]);
        end
        using NamespacedFunctions;
        assertEquals(8, namespacedFunctions.wbdfibhr(4));
    end
        
    function testPlusUsable
        try
            NamespacedFunctions.plus(4);
        catch
            assertStrEquals('MATLAB:undefinedVarOrClass', 
    
    function testImportAllUsable
        fail(not written);
            
    function testImportAllOverridesBuiltin
        fail(not written);