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
    %If you give a zero-size array as an argument, as in the last argument
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
    %Logical arguments will be unpacked as bits. Non-logical arguments must be
    %alighned to byte boundaries.
    %
    %You can give cell arrays or structs as arguments, and they will be
    %unpacked as necessary.
    %
    %BUGS: will not work on long integers yet, as 'dec2hex' and 'hex2dec'
    %are stupid along with MATLAB's handling of long ints in general
    %(the error produced reveals that max() doesn't even work for longs!)
    
    %Start by converting to hex
    hex = sprintf('%02x', bytes);

    pointer = 0;
    %iterate the over the template
    subs = iteratesubs(varargin);
    varargout = varargin;
    
    for i = 1:numel(subs)
        f = subsref(varargin, subs{i});
        if numel(f) == 0
            break;
        end
        [datachunk, nbytes] = frombytesstep(f, pointer, 1);
        varargout = subsasgn(varargout, subs{i}, datachunk);
        pointer = pointer + nbytes;
    end

    pointer2 = numel(bytes);
    for j = numel(subs):-1:i+1
        q = subsref(varargin, subs{j});
        if numel(q) == 0
            error('fromBytes:illegalArgument', 'Only one argument may be of zero size.');
        end
        [datachunk, nbytes] = frombytesstep(q, pointer, 1);
        varargout = subsasgn(varargout, subs{j}, datachunk);
        pointer2 = pointer2 - nbytes;
    end
    
    if numel(f) == 0
        datachunk = frombytesblank(f, pointer, pointer2-pointer);
        varargout = subsasgn(varargout, subs{i}, datachunk);
    end
    
    
    
    function [format, nbytes] = frombytesstep(format, pointer, dir)
        if islogical(format)
            %special handling for bitfields:
            nbytes = numel(format) / 8;
            if (numel(bytes) < pointer + nbytes*dir) || (pointer+nbytes*sign(dir) < 0)
                error('frombytes:notEnoughData', 'Not enough bytes for the given format.');
            end

            %grab data, binarize it
            x = hex( floor(pointer)*2+1 : ceil(pointer+nbytes)*2 );
            bin = dec2bin(hex2dec(x(:)), 4)' - '0';
            %chop off fractional bytes
            bin = bin( 8*(pointer-floor(pointer))+1 : end-8*(ceil(pointer+nbytes)-pointer-nbytes) );
            
            format(:) = bin;
        else
            if pointer ~= floor(pointer)
                error('frombytes:notByteAligned', 'Non-logical fields must be byte aligned.');
            end
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
    end



    function [format, nbytes] = frombytesblank(format, pointer, length)
        nonzeros = size(format) == 0;

        if sum(nonzeros) == 1
            dim = find(nonzeros);
        else
            format = reshape(format, 0, 1);
            dim = 1;
        end

        if islogical(format)
            %grow to the right number of planes
            dims = num2cell(max(size(format), 1));
            
            nplanes = length*8 / prod([dims{:}]);
            if nplanes ~= floor(nplanes)
                error('frombytes:unevenData', 'Data does not fill specified format evenly.');
            end
            
            h = hex(floor(pointer)*2+1:ceil(pointer+length)*2);
            bits = dec2bin(h(:), 4) - '0';
            bits = bits(1+8*(pointer-floor(pointer)):8*(pointer-floor(pointer)+length));
            
            dims{dim} = nplanes;
            format(dims{:}) = 0;
            format(:) = bits;
        else
            if pointer ~= floor(pointer) || length ~= floor(length)
                error('frombytes:notByteAligned', 'Non-logical fields must be byte aligned.');
            end
            %grow to one row, plane, whatever
            dims = num2cell(max(size(format), 1));
            format(dims{:}) = 0;
            element = format(1);
            s = whos('element', 'format');
            [bytesinelement, nbytes] = s.bytes;

            h = hex(pointer*2+1:(pointer+length)*2);

            if mod(numel(h), nbytes*2)
                error('frombytes:unevenData', 'Data does not fill specified format evenly.');
            end

            dims{dim} = numel(h) / (nbytes*2);
            dimsub = cellfun(@(x)1:x, dims, 'UniformOutput', 0);
            toconvert = reshape(h, bytesinelement*2, [])';

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
end