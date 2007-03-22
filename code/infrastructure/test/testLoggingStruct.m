%a "logging struct" is an object that behaves like a struct, but logs
%whenever its entries are assigned or changed.

this = inherit(TestCase(), public ...
    ( @testLoggingStruct ...
    , @testSubsref ...
    , @testSubsrefArray
    , @testSubsrefNested ...
    , @testSubsasgn ...
    , @testSubsasgnArray ...
    , @testSubsasgnNested ...
    , @testFieldnames ...
    , @testSetfield ...
    , @testGetfield ...
    , @testIsfield ...
    , @testRmfield ...
    , @testOrderfields ...
    , @testSubstruct ...
    , @testStructfun ...
    );

%test: behaves as struct

function testLoggingStruct
    %the initializer behaves as struct() as far as sizes of objects go
    a = loggingStruct('a', 1, 'b', 2);
    assertEquals(1, numel(a));
    
    a = loggingStruct('a', {1}, 'b', {2});
    assertEquals(1, numel(a));
    
    a = loggingStruct('a', {1 2}, 'b', {2 3});
    assertEquals([1 2], size(a));
    
    a = loggingStruct('a', {}, 'b', {});
    assertEquals(0, numel(a));
    
    %more stupid DWIM behavior of struct() is replicated, grr. Cell array
    %arguments are interpreted differently from scalar arguments, except
    %for cell arrays of one element which are interpreted as scalars.
    
    %one entry is 
    a = loggingStruct('a', {1}, 'b', {});
    assertEquals(0, numel(a));
    
    a = loggingStruct('a', {1 2}', 'b', 2);
    assertEquals([2 1], size(a));
    
    a = loggingStruct('a', {1 2}', 'b', {2});
    assertEquals([2 1], size(a));
    
    try
        a = loggingStruct('a', {1 2}, 'b', {});
        fail('expected error');
    catch
        %pass
    end
end

function testSubsref
    %you should be able to use subsref() properly
    a = loggingStruct('a', 1, 'b', 2);
    
    assertEquals(1, a.a);
    assertEquals(1, a.b); 
end

function testSubsasgn
    a = loggingStruct('a', 1, 'b', 2);
    a.b = 4;
    assertEquals(4, a.b);
end
    
function testSubsrefArray
    a = loggingStruct('a', {1, 2}, 'b', {'aa', 'bb'});
    
    assertEquals(1, a(1).a);
    assertEquals('bb', a(2).b);
    
    [one, two] = a.b;
    assertEquals('aa', one);
    assertEquals('bb', two);
end

function testSubsasgnArray
    a = loggingStruct('a', {1, 2}, 'b', {'aa', 'bb'});
    
    a(1).a = 3;
    assertEquals(3, a(1).a);
    
    %this might be tricky
    [a.b] = deal(1, 2)
    assertEquals(1, a(1).b);
    assertEquals(2, a(2).b);
end

function testSubsrefNested
    a = loggingStruct('a', struct('c', 1), 'b', struct('d', {{2, 3}}));
    
    assertEquals(1, a.a.c);
    assertEquals(2, a.b.d{1});
end


function testSubsasgnNested
    a = loggingStruct('a', struct('c', 1), 'b', struct('d', {{2, 3}}));
    
    a.a.c = 43
    assertEquals(43, a.a.c);
    
    a.b.d{1} = 928;
    assertEquals(928, a.b.d{1});
end
