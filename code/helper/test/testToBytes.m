function this = testToBytes(varargin)

    persistent init__;
    this = inherit(TestCase(), BaseBytesTest(), autoobject(varargin{:}));
    
    function check(format, input, output, varargin)
        assertEquals ...
            ( output ...
            , tobytes(format, input, varargin{:}) ...
            );
    end

    function testIntRange()
        widths = {'8', '16', '32'};
        for class = cat(2, strcat('uint', widths), strcat('int', widths));
            mx = intmax(class{1});
            mn = intmin(class{1});
            
            xx = double(mx) + max(1, eps(double(mx)));
            nn = double(mn) - max(1, eps(double(mn)));
            
            try
                tobytes(cast(0, class{1}), mx);
            catch
                e = lasterror;
                e.message = [class{1} ' max: ' e.message];
                rethrow(e)
            end
            
            try
                tobytes(cast(0, class{1}), mn);
            catch
                e = lasterror;
                e.message = [class ' min: ' e.message];
                rethrow(e)
            end
            
            try
                tobytes(cast(0, class{1}), xx);
                assert(0, 'should have made an error for %s upper bound', class{1});
            catch
                e = lasterror;
                assertEquals('tobytes:outOfRange', e.identifier);
            end

            try
                tobytes(cast(0, class{1}), nn);
                assert(0, 'should have made an error for %s lower bound', class{1});
            catch
                e = lasterror;
                assertEquals('tobytes:outOfRange', e.identifier);
            end
        end
    end

    function testIntegerToLogicalRange
        try
            tobytes ...
                ( {false(5,1) false(3, 1)} ...
                , {2, 8} ...
                );
            assert(0, 'should have an out of range error', class{1});
        catch
            e = lasterror;
            assertEquals('tobytes:outOfRange', e.identifier);
        end
        
        try
            tobytes ...
                ( {false(5,1) false(3, 1)} ...
                , {-1, 7} ...
                );
            assert(0, 'should have an out of range error', class{1});
        catch
            e = lasterror;
            assertEquals('tobytes:outOfRange', e.identifier);
        end    
    end

    %for toBytes only, you can provide an incomplete struct on the data
    %argument and it will take values from the street side.
    %values from the 
    function testIncompleteStructs()
        this.check...
            ( struct('a', uint8(0), 'reserved', uint8(0), 'b', uint8(0), 'reserved2', uint8(1)) ...
            , struct('a', 100, 'b', 200) ...
            , uint8([100 0 200 1]) ...
            );
    end

end