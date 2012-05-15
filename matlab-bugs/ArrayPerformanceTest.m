classdef ArrayPerformanceTest
    properties
        %which N to test.
        range = floor(logspace(1, 7, 35))
        
        results = struct();
        
        %because some of this is just SO SLOW, don't continuecollecting if
        %it
        %runs longer than this.
        max_allowable_time = 3;
    end
    
    methods
        function self = ArrayPerformanceTest(tests)
            if ~exist('tests', 'var')
                mc = metaclass(self);
                tests = cellfun(mc.Methods()', @(x)method{1}.Name, ...
                                'UniformOutput', 0);
                tests = tests(strncmp(tests, 'test', 4));
            end

            self = self.runTests(tests);
        end
        
        function [self, results] = runTests(self, tests)
            results = struct();
            
            %collect and run all tests (tests are methods of 'self' that
            %contain 'test' in the name.')
            
            for methodInACell = tests(:)'
                method = methodInACell{1}; %standard boilerplate workaround for running a for loop over a cell
                
                %Time invications with various sizes of array, unless it
                %just gets too long.
                
                %Here, we allocate the whole array, then truncate it after
                %the point where we gave up.
                
                %I present this to you as an example of the kinds of
                %rigamarole that you have to do to avoid dynamically
                %reallocating a growing array. Compare with how you
                %would spell this in Python....
                
                disp(method);
                f = str2func(method);
                N = self.range;
                times = zeros(size(self.range));
                
                %repeat and discard the early ones for jit burn in
                for i = [4 3 2 1 1:numel(self.range)]
                    %disp(self.range(i))
                    
                    %Yowza. Take out this guard and see what happens!
                    if (strcmp(method, ...
                            'testGrowMatlabExampleLinkedList') ...
                            && (self.range(i) >= ...
                            get(0, 'recursionLimit') - 10))
                        i = i - 1;
                        break;
                    end
                    
                    tic;
                    f(self, self.range(i));
                    times(i) = toc;
                    
                    if times(i) > self.max_allowable_time
                        disp(struct(method, self.range(i)));
                        break
                    end
                end
                N(i+1:end) = [];
                times(i+1:end) = [];
                results.(method).N = N;
                results.(method).t = times;
            end
            
            self.results = results;
        end
        
        function showplot(self)
            figure(); hold on;
            measured = fieldnames(self.results);
            colors = ['k','b','r','g','m'];
            shapes = ['o','s','d','^','v','x'];
            for i = 1:numel(measured);
                plot(self.results.(measured{i}).N, self.results.(measured{i}).t, ...
                    [colors(mod(i, numel(colors))+1) '-' shapes(mod(i, numel(shapes)) + 1)]);
            end
            if numel(measured) <= 6
                legend(measured{:}, 'Location', 'EastOutside');
            else
                legend(measured{:}, 'Location', 'SouthEastInside');
            end
            xlabel('Input size');
            ylabel('Execution time');
            
            %Plot this on a log-log plot.
            set(gca, 'XScale', 'log', 'YScale', 'log', 'XLim', [10 1E7], 'Ylim', [1e-5 10]);
            axis square;
            hold off;
        end
                        
        %the first four tests are strightforward, growing vs. reallocating
        %arrays and cells.  It has been claimed that MATLAB't JIT can
        %detect this kind of thing and make the "growing" case nearly as
        %fast as the "preallocated" case. Of course, this doesn't actually
        %happen.
        function testPreallocatedArray(self, N)
            C = zeros(1,N);
            for i = 1:N
                C(i) = rand();
            end
        end
        
        function testGrowingArray(self, N)
            C = [];
            for i = 1:N
                C(i) = rand();
            end
        end
        
                
        function testGrowingArrayOutsideMethod(self, N)
            grow(N);
        end
        
        function testPreallocatedCell(self, N)
            C = cell(1, N);
            for i = 1:N
                C{i} = rand();
            end
        end
        
        function testGrowingCell(self, N)
            C = {};
            for i = 1:N
                C{i} = rand(); %#ok
            end
        end
        
        %the next two tests simulate the all-too-frequent case where you
        %read from a connection or scan gathering cases until you stop. No
        %help from the JIT on this one, as if there was help previously.
        function testGrowingArrayUntilToldToStop(self, N)
            getter = makeGetter(N);
            
            i = 1;
            A = [];
            while 1
              x = getter();
              if isempty(x)
                  break;
              end
              A(i) = x; %#ok
              i = i + 1;
            end
        end
        
        function testGrowingCellUntilToldToStop(self, N)
            getter = makeGetter(N);
            
            i = 1;
            A = {};
            while 1
              x = getter();
              if isempty(x)
                  break;
              end
              A{i} = x; %#ok
              i = i + 1;
            end
        end
        
        %The performance blows up even worse if a cell array is accessed
        %through a handle to a nested function. It hardly matters of you
        %grow or not, because every time you call a handle to a nested
        %function, the 
        function testPreallocatedArrayInNestedFunction(self, N)
            c = makeSetter(zeros(1,N));
            for i = 1:N
                c(i, rand());
            end
        end
        
        function testPreallocatedCellInNestedFunction(self, N)
            c = makeSetter(cell(1,N));
            for i = 1:N
                c(i, {rand()});
            end
        end
        
        function testGrowingArrayInNestedFunction(self, N)
            c = makeSetter([]);
            for i = 1:N
                c(i, rand());
            end
        end
        
        function testGrowingCellInNestedFunction(self, N)
            c = makeSetter({});
            for i = 1:N
                c(i, {rand()});
            end
        end
        
        %Similarly, the performance explodes when the array is a slot of a
        %handle object. Oddly, this is even slower than the nested function
        %case.
        function testPreallocatedArrayInHandleObject(self, N)
            c = HandleContainer(zeros(1,N));
            
            for i = 1:N
                c.store(i, rand());
            end
        end
        
        function testPreallocatedCellInHandleObject(self, N)
            c = HandleContainer(cell(1,N));
            
            for i = 1:N
                c.store(i, {rand()});
            end
        end
        
        function testGrowingArrayInHandleObject(self, N)
            c = HandleContainer(zeros(1,N));
            
            for i = 1:N
                c.store(i, rand());
            end
        end
        
        function testGrowingCellInHandleObject(self, N)
            c = HandleContainer(cell(1,N));
            for i = 1:N
                c.store(i, {rand()});
            end
        end
        
        %and what about value objects? Can you use a "value object" as an
        %efficient container, or does every modification of a value object
        %essentially require a deep copy?
        function testPreallocatedArrayInValueObject(self, N)
            c = ValueContainer(zeros(1,N));
            
            for i = 1:N
                c = c.store(i, rand());
            end
        end
        
        function testPreallocatedCellInValueObject(self, N)
            c = ValueContainer(cell(1,N));
            
            for i = 1:N
                c = c.store(i, {rand()});
            end
        end
        
        function testGrowingArrayInValueObject(self, N)
            c = ValueContainer(zeros(1,N));
            
            for i = 1:N
                c = c.store(i, rand());
            end
        end
        
        function testPushdownCell(self, N)
            a = {};
            for i = 1:N
                a = {rand() a};
            end
        end
        
        function testGrowingCellInValueObject(self, N)
            c = ValueContainer(cell(1,N));
            for i = 1:N
                c = c.store(i, {rand()});
            end
        end
        
        %what about the "linked list" example from MATLAB's own handle
        %objects documentation? I mean, the entire reason you'd want to
        %build a linked list is because inserts are O(N) right????
        function testGrowMatlabExampleLinkedList(self, N)
            atBeginning = dlnode();
            atEnd = atBeginning;
            for i = 1:N
                newNode = dlnode(i);
                newNode.insertAfter(atEnd);
                atEnd = newNode;
            end
        end
    end
end

function f = makeGetter(nAvail)
    nGot = 0;
    function out = getOne
        if nAvail >= nGot
            out = rand();
            nGot = nGot + 1;
        else
            out = [];
        end
    end
    f = @getOne;
end

function setter = makeSetter(init)
    value = init;
    function set(where, what)
        value(where) = what;
    end
    setter = @set;
end