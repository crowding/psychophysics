function this = assigninTest

this = final(...
    @testAssignIn...
    ,@testMakeFunctionIn...
    ,@testAssignInClosure...
    ,@testAutomaticAccessor...
    ,@testAutomaticMutator...
    );

    function testAssignIn
        loc = 1;
        assignInSub();
        assertEquals(2, loc);
    end

    function assignInSub
        assignin('caller', 'loc', 2);
    end

    function testMakeFunctionIn
        foo = []; %must declare
        makeFunctionIn()
        assertEquals(5, foo());
    end

    function makeFunctionIn
        assignin('caller', 'foo', @() 5);
    end

    function testAssignInClosure
        %the conventional way of making an accessor
        [accessor, mutator] = makeClosure();
        
        assertEquals(accessor(), 5);
        mutator(6);
        assertEquals(accessor(), 6);
        
        function [accessor, mutator] = makeClosure
            a = 5;
            accessor = @get;
            function v = get
                v = a;
            end
            mutator = @set;
            function v = set(v)
                a = v;
            end
        end
    end

    function testAutomaticAccessor
        %can we make the accessor automatically?
        [accessor, mutator] = makeClosure();
        
        assertEquals(5, accessor());
        mutator(6);
        assertEquals(6, accessor());
        
        function [accessor, mutator] = makeClosure
            a = 5;
            accessor = makeAccessor(a);
            mutator = @set;
            function v = set(v)
                a = v;
            end
        end
        
        function acc = makeAccessor(var)
            %this works via an eval for every access
            acc = evalin('caller', ['@()eval(''' inputname(1) ''')']);
            
            %%this works, and no direct eval during access, but uses
            %%functions().
            %acc = evalin('caller', '@()0');
            %subs = substruct('.', 'workspace', '{}', {2}, '.', inputname(1));
            %acc = @()subsref(functions(acc), subs);
        end
    end
        
    function testAutomaticMutator
        %can we make the mutator automatically?
        [accessor, mutator] = makeClosure();
        
        assertEquals(5, accessor());
        mutator(6);
        assertEquals(6, accessor());
        
        function [accessor, mutator] = makeClosure
            a = 5;
            tmp = []
            accessor = @get;
            function v = get
                v = a;
            end
            mutator = makeMutator(a);
        end
        
        function mut = makeMutator(var)
            varname = inputname(1);

            %To mutate, we want this:
            
            %assign = @(x) assignin('caller', varname, x);
            %to be evaluated by a function in caller's lexical context.
            
            %So:
            %push this handle into the caller's namespace via a tmp
            %variable (todo-- we have a perfectly good variable name to
            %use...)
            %assignin('caller', 'tmp', @(x) assignin('caller', varname, x));
            
            assignin('caller', 'tmp', @(x) eval([varname '=' mat2str(x)]));

            
            %now have the caller capture it inside a function handle
            %(giving it context)
            mut = evalin('caller', '@(x) tmp(x)');
        end
    end
end
%{
function testAssignInAnonymous
%using assignin inside a closed-over function, you can
%

[fn, check] = setup();
fn('bar');
assertEquals('bar', check());

function [fn, check] = setup
that = 'foo';
%fn = @(val) assigninme('that', comma(that, val));
fn = @setthat;

check = @()that;

function setthat(val)
that = that;
assigninme('that', comma(that, val));
end
end

function val = ident(val)
end

function val = comma(that, val);
end

function assigninme(name, val)
assignin('caller', name, val);
end
end

end

function val = slot(name, val)
if (nargin < 3)
this.(name) = val;
else
val = this.(name);
end
end
%}
