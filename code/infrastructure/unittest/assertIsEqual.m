function assertIsEqual(expected, actual)
    if ~isequal(expected, actual)
        error('assert:assertionFailed', 'arguments are not equal');
    end
end