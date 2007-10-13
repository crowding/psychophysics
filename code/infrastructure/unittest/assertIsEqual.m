function assertIsEqual(expected, actual)
    if ~isequal(expected, actual)
        error('assert:assertIsEqual', 'arguments are not equal');
    end
end