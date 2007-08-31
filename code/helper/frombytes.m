function varargout = frombytes(bytes, varargin)

    %Converts an array of bytes to given numeric types. The format
    %specification is given as array arguments of the desired type and size.
    %
    %Usage example:
    %
    %[a, b, c] = frombytes( [123 23 12 32 32 233], int8(1), int16([1 1]), uint8([]) )
    %a =
    %  123
    %b =
    %   4130  31744
    %c =
    %  233
    %
    %If you give a zero-size array as an argument, as in the past argument
    %above, it will 'soak up' all the data that it can find. If you give a
    %zero-size array that has one dimension of size zero, it will seek to
    %fill in data according to the sizes of the nonzero dimensions.
    %Otherwise it will make a column vector. Only one zero-sized array is
    %supported.
    %
    %That is, frombytes(bytes, zeros(2, 0)) returns a 2-by-N array of
    %doubles, while frombytes(bytes, zeros(1, 1, 0)) returns a 1-by-1-by-M
    %array of doubles.
    %
    %Errors will be thrown if there is not enough data, if there is too
    %much data, if non-numeric or complex values are supplied, or if the
    %number of bytes does not fill out a zero-sized format argument evenly.
    %
    %BUGS: will not work on long integers yet, as 'dec2hex' and 'hex2dec'
    %are stupid along with MATLAB's handling of long ints in general
    %(the error produced reveals that max() doesn't even work for longs!)
    
    %Start by converting to hex
    hex = sprintf('%02x', bytes);

    pointer = 0;
    for i = 1:numel(varargin)
        f = varargin{i};
        if numel(f) == 0
            break;
        end
        [varargout{i}, nbytes] = frombytesstep(f, pointer, 1);
        pointer = pointer + nbytes;
    end

    pointer2 = numel(bytes);
    for j = numel(varargin):-1:i+1
        if numel(varargin{j}) == 0
            error('fromBytes:illegalArgument', 'Only one argument may be of zero size.');
        end
        [varargout{j}, nbytes] = frombytesstep(format, pointer2, -1);
        pointer2 = pointer2 - nbytes;
    end
    
    if numel(varargin{i}) == 0
        varargout{i} = frombytesblank(varargin{i}, hex(pointer*2+1:pointer2*2));
    end
    
    
    
    function [format, nbytes] = frombytesstep(format, pointer, dir)
        element = format(1); %#ok
        s = whos('element', 'format');
        [bytesinelement, nbytes] = s.bytes;

        if (numel(bytes) < pointer + nbytes*dir) || (pointer+nbytes*sign(dir) < 0)
            error('frombytes:notEnoughData', 'Not enough bytes for the given format.');
        end

        if isnumeric(format)
            if isreal(format)
                if (dir > 0)
                    toconvert = reshape(hex(1+pointer*2:(pointer+nbytes)*2), [], bytesinelement*2);
                else
                    toconvert = reshape(hex((pointer-nbytes)*2+1:pointer*2), [], bytesinelement*2);
                end
                if isinteger(format)
                    x = hex2dec(toconvert);
                    if ~any(class(format) == 'u')
                        %signed data format, use twos complement...
                        mx = intmax(class(format));
                        x(x > mx) = x(x > mx) + 2*double(intmin([class(format)]));
                    end
                    format(:) = x;
                else
                    format(:) = hex2num(toconvert);
                end
            else
                error('frombytes:unsupportedDataType', 'Complex data not supported');
            end
        else
            error('frombytes:unsupportedDataType', 'Data type ''%s'' not supported', class(s));
        end
    end



    function [format, nbytes] = frombytesblank(format, hex)
        nonzeros = size(format) == 0;

        if sum(nonzeros) == 1
            dim = find(nonzeros);
        else
            format = reshape(format, 0, 1);
            dim = 1;
        end

        %grow to one row, plane, whatever
        dims = num2cell(max(size(format), 1));
        format(dims{:}) = 0;
        element = format(1);
        s = whos('element', 'format');
        [bytesinelement, nbytes] = s.bytes;

        if mod(numel(hex), nbytes*2)
            error('frombytes:unevenData', 'Data does not fill specified format evenly.');
        end
        
        dims{dim} = numel(hex) / (nbytes*2);
        dimsub = cellfun(@(x)1:x, dims, 'UniformOutput', 0);
        toconvert = reshape(hex, bytesinelement*2, [])';
        
        if isnumeric(format)
            if isreal(format)
                if isinteger(format)
                    x = hex2dec(toconvert);
                    if ~any(class(format) == 'u')
                        %signed data format...
                        mx = intmax(class(format));
                        x(x > mx) = x(x > mx) + 2*double(intmin([class(format)]));
                    end
                    
                    format(dimsub{:}) = reshape(x, dims{:});
                else
                    format(dimsub{:}) = reshape(hex2num(toconvert), dims{:});
                end
            else
                error('frombytes:unsupportedDataType', 'Complex data not supported');
            end
        else
            error('frombytes:unsupportedDataType', 'Data type ''%s'' not supported', class(s));
        end
    end
end