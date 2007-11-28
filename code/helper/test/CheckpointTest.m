function this = CheckpointTest(varargin)
    persistent init__; %#ok
    this = inherit(TestCase(), autoobject(varargin{:}));
    
    function testCheckpoint()
        checkpoint(Inf);
        checkpoint();
        checkpoint();
        
        [hist, stacks, transitioncounts, transitiontimes] = checkpoint();
        
        assertEquals([3, 2], size(hist));
        assertEquals([0 1 0; 0 0 1; 0 0 0], transitioncounts);
        assert(all(transitiontimes(transitioncounts > 0) > 0));
        assert(all(transitiontimes(transitioncounts == 0) == 0));
        assertEquals(3, numel(stacks));
    end

    function testCheckpointFolding
        checkpoint(Inf);
        checkpoint();
        for i = 1:5
            checkpoint();
        end
        
        [hist, stacks, transitioncounts, transitiontimes] = checkpoint();
        
        assertEquals([7, 2], size(hist));
        assertEquals([0 1 0; 0 0 1; 0 0 4], transitioncounts);
        assert(all(transitiontimes(transitioncounts > 0) > 0));
        assert(all(transitiontimes(transitioncounts == 0) == 0));
        assertEquals(3, numel(stacks));
    end

    function testMaxDepth
        function n = fact(n)
            checkpoint();
            if (n == 0)
                n = 1;
            else
                n = n * fact(n-1);
            end
        end
        
        checkpoint(Inf);
        fact(5);
        [h, stacks, tcounts] = checkpoint();
        
        assertEquals(7, numel(stacks));
        assertEquals(tcounts, diag([1 1 1 1 1 1], 1));
        
        checkpoint(1);
        fact(5);
        [h, stacks, tcounts] = checkpoint();
        assertEquals(2, numel(stacks));
        assertEquals([0 1; 0 5], tcounts);
        
        checkpoint(2);
        fact(5);
        [h, stacks, tcounts] = checkpoint();
        assertEquals(3, numel(stacks));
        assertEquals([0 1 0; 0 0 1; 0 0 4], tcounts);
    end
end