function this = assigninTest

this = inherit(TestCase(), ...
    public ...
        ( @testAssignIn...
        , @testMakeFunctionIn...
        , @testAssignInClosure...
        , @testAutomaticAccessor...
        , @testAutomaticMutator...
        , @testFileLoader...
        ) ...
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
            %vs = evalin('caller', 'who()')
            %this works via an eval for every access
            %acc = evalin('caller', ['@()eval(''' inputname(1) ''')']);
            
            %%this works, and no direct eval during access, but uses
            %%functions().
            acc = evalin('caller', '@()0');
            subs = substruct('.', 'workspace', '{}', {2}, '.', inputname(1));
            acc = @()subsref(functions(acc), subs);
        end
    end

    function assign(varname, x)
        assignin('caller', varname, x);
    end

    function testAutomaticMutator
        %can we make the mutator automatically?
        [accessor, mutator] = makeClosure();
        
        assertEquals(5, accessor());
        mutator(6);
        assertEquals(6, accessor());
        
        function [accessor, mutator] = makeClosure
            a = 5;
            b = 3;
            
            function do(x)
                %a = [];
                b = [];
                assign('b', x);
                x();
            end
            
            accessor = @get;
            function v = get
                v = a;
            end
            mutator = makeMutator(a, @do);
        end
        
        function mut = makeMutator(var, do)
            varname = inputname(1);
            mut = evalin('caller', ['@(v) eval(''' varname '=v'')']);
        end
    end

    function testFileLoader()
        loader = [];
        getter = [];
        function h = makeloader()
            h = evalin('caller', '@(x)load(x)')
        end
        
        function closure()
            var1 = 'foo';
            var2 = 'bar';
            
            getter = @get;
            function [a, b] = get()
                a = var1;
                b = var2;
            end
            
            loader = makeloader();
        end
        
        closure();
        
        [a, b] = getter();
        assertEquals('foo', a); assertEquals('bar', b);
        
        file = struct('var1', 'baz', 'var2', 'quux');
        name = tempname;
        save(name, '-struct', 'file');
        
        loader(name);
        [a, b] = getter();
        assertEquals('baz', a); assertEquals('quux', b);
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
