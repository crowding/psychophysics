function slowLexicalScope
    
    timeout = 5;
    n = floor(logspace(2, 5, 20));
    %@argument_test, 
    methods = {@lexical_test, @global_struct_test, @persistent_struct_test, @java_test, @persistent_test};

    [inputs, times] = cellfun(@(fn)gettimes(fn, timeout, n), methods, 'UniformOutput', 0);
    
    plotargs = {inputs{:}; times{:}};
    loglog(plotargs{:});
    
    xlabel('input size');
    ylabel('execution time');
    
    names = cellfun(@func2str, methods, 'UniformOutput', 0);
    legend(names{:}, 'Location', 'NorthWest', 'Interpreter', 'none');
end

function [inputs, times] = gettimes(fn, timeout, inputs)
    times = NaN(size(inputs));
    for i = 1:numel(inputs)
        t1 = cputime;
        fn(inputs(i));
        t = cputime - t1;
        times(i) = t;
        disp({func2str(fn), inputs(i), t});
        if (t > timeout)
            break;
        end
    end
end

%All implementations do the same thing: build a linked list of random
%numbers and compute their sum. One of them keeps the linked list in nested
%functions and the other keeps it in a struct argument that is passed in and out.
%I don't think there should be a reason why one should be particularly
%slower than the other. There certainly should not be a reason for one to
%have a completely different asymptotic complexity than the other.

function s = lexical_test(n)
    [add, sum] = lexical_linked_list();
    for i = 1:n
        add(i);
    end

    s = sum();
end

function [addfn, sumfn] = lexical_linked_list
    list = {};
    
    addfn = @add;
    sumfn = @sum;

    function add(n)
        list = {n, list};
    end

    function s = sum
        l = list;
        s = 0;
        while ~isempty(l)
            s = s + l{1};
            l = l{2};
        end
    end
end

%This should do the same thing as above, but passes the list around
%externally in a struct instead of getting them from the lexical closure.
%
%programs written this way cannot take advantage of the reference behavior
%of nested function scope, which means we are limited to a language with no
%reference type whatsoever, which is nearly worthless.

function s = argument_test(n)
    [add, sum, arg] = argument_linked_list();
    for i = 1:n
        arg = add(arg, i);
    end
    
    [s, arg] = sum(arg);
end

function [addfn, sumfn, arg] = argument_linked_list;
    arg.list = {};
    addfn = @add;
    sumfn = @sum;
    
    function out = add(in, n)
        out = in;
        out.list = {n, in.list};
    end

    function [s, out] = sum(in)
        l = in.list;
        s = 0;
        while ~isempty(l)
            s = s + l{1};
            l = l{2};
        end
        out = in;
    end
end

%This method uses a Java vector for the data
%structure. This is not a general purpose solution, since MATLAB's Java
%interface does not provide for passing structs, MATLAB objects, or
%function handles to Java function arguments, and the translation of data
%across the Java<->matlab interface is lossy and involves deep copies.
%
%This has the right asymptotic complexity, has the right reference behavior,
%but is an order of magnitude too slow.
function s = java_test(n)
    [add, sum] = java_linked_list();
    
    for i = 1:n
        add(i);
    end

    s = sum();
end

function [addfn, sumfn, arg] = java_linked_list;
    list = java.util.Vector;
    
    addfn = @add;
    sumfn = @sum;
    
    function add(n)
        list.add(n);
    end

    function s = sum
        e = list.elements();
        s = 0;
        while(e.hasMoreElements())
            s = s + e.nextElement();
        end
    end
end

%This method uses a persistent variable. I shouldn't have to go into how
%poor a choice this is in terms of maintainability, but it has the right
%speed, at the expence of any reference behavior (or any copy-on-write
%behavior, wince there acn only be one instance of the list at any given
%time...)
function s = persistent_test(n)
    [add, sum] = persistent_linked_list();
    for i = 1:n
        add(i);
    end

    s = sum();
end

function [addfn, sumfn] = persistent_linked_list
    persistent list;
    list = {};
    
    addfn = @add;
    sumfn = @sum;

    function add(n)
        list = {n, list};
    end

    function s = sum
        l = list;
        s = 0;
        while ~isempty(l)
            s = s + l{1};
            l = l{2};
        end
    end
end

function s = persistent_struct_test(n)
    [add, sum] = persistent_struct_linked_list();
    for i = 1:n
        add(i);
    end

    s = sum();
end

function [addfn, sumfn] = persistent_struct_linked_list
    persistent referents___;
    
    if isempty(referents___)
        list = struct();
    end
    [tmp, name] = fileparts(tempname);
    
    index = 0;
    
    referents___.(name) = {};
    
    addfn = @add;
    sumfn = @sum;

    function add(n)
        referents___.(name) = {n, referents___.(name)};
    end

    function s = sum
        l = referents___.(name);
        s = 0;
        while ~isempty(l)
            s = s + l{1};
            l = l{2};
        end
    end
end

function s = global_struct_test(n)
    [add, sum] = global_struct_linked_list();
    for i = 1:n
        add(i);
    end

    s = sum();
end

function [addfn, sumfn] = global_struct_linked_list
    global referents___;
    if isempty(referents___)
        list = struct();
    end
    [tmp, name] = fileparts(tempname);
    
    index = 0;
    
    referents___.(name) = {};
    
    addfn = @add;
    sumfn = @sum;

    function add(n)
        referents___.(name) = {n, referents___.(name)};
    end

    function s = sum
        l = referents___.(name);
        s = 0;
        while ~isempty(l)
            s = s + l{1};
            l = l{2};
        end
    end
end