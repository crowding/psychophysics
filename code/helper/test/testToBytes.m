function this = testToBytes(varargin)

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

end