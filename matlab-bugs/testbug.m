function testbug()
    a0 = struct('var', []);
    a1 = struct('var', [1]);
    a2 = struct('var', [2]);
    a3 = struct('var', [3]);
    
    goal = reduce_forloop(@ConcatenateVarField, a0, [a1 a2 a3]);
    result =       reduce(@ConcatenateVarField, a0, [a1 a2 a3]);
    
    if isequalwithequalnans(goal, result)
        disp('------------there is not a bug')
    else
        disp('expected:')
        disp(goal)
        disp('got:')
        disp(result)
        disp('------------there is a bug')
    end
end

function accum = reduce(fn, accum, array)
    arrayfun(@step, array);
        function step(a)
            accum = fn(accum, a);
        end
end

function accum = reduce_forloop(fn, accum, array)
    for i = 1:numel(array)
        accum = fn(accum, array(i));
    end
end

function C = ConcatenateVarField(A, B)
    if (isempty(A.var)), C = B; return; end;
    if (isempty(B.var)), C = A; return; end;
    
    C.var = [A.var, B.var];
end