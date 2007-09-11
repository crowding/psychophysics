function bytes = tobytes(varargin)
    %Converts the arguments into a string of bytes using big-endian 
    %format and IEEE format for floats.
    %
    %Example:
    %
    %>> bytes=tobytes([2.3 0], uint16(258))
    %bytes =
    %  Columns 1 through 16
    %   70    0    6    0    6    0   38    0  102    0  102    0  102    0  102    0
    %  Columns 17 through 18
    %    0   18
    %
    out = cellfun(@tobytesstep, varargin, 'UniformOutput', 0);
    bytes = [out{:}];
end

function bytes = tobytesstep(in)
    if isempty(in)
        bytes = uint8([]);
    end
    element = in(1:min(1, numel(in))); %#ok
    s = whos('element');
    width = s.bytes;
    
    if isnumeric(in)
        if isreal(in)
            if isinteger(in)
                if any(in < 0) %signed data
                    adj = -2*double(intmin(class(in)));
                    in = double(in);
                    in(in < 0) = in(in < 0) + adj;
                end
                hex = dec2hex(in, width*2);
            else
                hex = num2hex(in);
            end
        else
            error('tobytes:unsupportedDataType', 'Complex data not supported');
        end
    else
        error('tobytes:unsupportedDataType', 'Data type ''%s'' not supported', class(in));
    end

    bytes = uint8(hex2dec(reshape(hex, 2, [])'))';
end
