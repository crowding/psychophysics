function output = frombytes(bytes, template, varargin)

    defaults = struct('littleendian', 0, 'enum', 1);
    params = options(defaults, varargin{:});
    
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
    %Logical template components will be unpacked as bits. Non-logical
    %arguments must be alighned to byte boundaries. If the first part of a
    %logical template component is set to 1, each column will be converted
    %to an unsigned integer and the dimensions will be shifted left.
    %
    %You can give cell arrays or structs as arguments, and they will be
    %unpacked as necessary.
    %
    %You can give an enum in the format argument as a structure with
    %'enum_' a special field; the value of enum_ determined the field
    %format and the other values of the struct determine the naems and
    %values. For instance:
    %
    %frombytes([132], struct('enum_', uint8(0), 'Vref', 132, 'GND', 133))
    %ans =
    %Vref
    %
    %You can suppress the enumeration translation by passing arguments
    %'enum', 0.
    %
    %BUGS: will not work on long integers, as 'dec2hex' and 'hex2dec'
    %are stupid along with MATLAB's handling of long ints in general.
    %(THERE ARE NO ARITHMETIC OPERATIONS FOR LONGS. THERE ARE NO BITWISE
    %OPERATIONS FOR SIGNED INTS. WTF.)
    
    %Start by converting to hex
    hex = sprintf('%02x', bytes);

    pointer = 0;
    %iterate the over the template
    [subs, enums] = iteratesubs(template);
    output = template;
    
    for i = 1:numel(subs)
        f = ssubsref(template, subs{i});
        
        if numel(f) == 0
            break;
        end
        [datachunk, nbytes] = frombytesstep(f, pointer, 1, params);
        output = ssubsasgn(output, subs{i}, datachunk);
        pointer = pointer + nbytes;
    end

    pointer2 = numel(bytes);
    for j = numel(subs):-1:i+1
        q = ssubsref(template, subs{j});
        if numel(q) == 0
            error('fromBytes:illegalArgument', 'Only one argument may be of zero size.');
        end
        [datachunk, nbytes] = frombytesstep(q, pointer2, -1, params);
        output = ssubsasgn(output, subs{j}, datachunk);
        pointer2 = pointer2 - nbytes;
    end
    
    if numel(f) == 0
        datachunk = frombytesblank(f, pointer, pointer2-pointer, params);
        output = ssubsasgn(output, subs{i}, datachunk);
    end
    
    for i = 1:numel(enums)
        lookup = enums{i}.s;
        value = ssubsref(output, [lookup struct('type', '.', 'subs', 'enum_')]);
        if params.enum
            value = enumToString(value, enums{i}.enum);
        end
        output = ssubsasgn(output, lookup, value);
    end
    
    function r = ssubsref(s, subs)
        if isempty(subs)
            r = s;
        else
            r = subsref(s, subs);
        end
    end

    function s = ssubsasgn(s, subs, a)
        if isempty(subs)
            s = a;
        else
            s = subsasgn(s, subs, a);
        end
    end
    
    function [format, nbytes] = frombytesstep(format, pointer, dir, params)
        if islogical(format)
            %special handling for bitfields:
            nbytes = numel(format) / 8;
            if (numel(bytes) < pointer + nbytes*dir) || (pointer+nbytes*sign(dir) < 0)
                error('frombytes:notEnoughData', 'Not enough bytes for the given format.');
            end

            %grab data, binarize it
            x = hex( floor(pointer)*2+1 : ceil(pointer+nbytes)*2 );
            bin = dec2bin(hex2dec(x(:)), 4)' - '0';
            if params.littleendian
                %flip order of bits within bytes for the next step
                bin = reshape(flipud(reshape(bin, 8, [])), size(bin));
            end
            %chop off fractional bytes
            bin = bin( 8*(pointer-floor(pointer))+1 : end-8*(ceil(pointer+nbytes)-pointer-nbytes) );
            
            %if the first entry in the logical is true, then convert to an
            %unsigned int (or ints if there are multiple columns)
            if format(1)
                sf = num2cell(size(format));
                bin = permute(reshape(bin, size(format)), [2 1 3:numel(sf)]);
                if params.littleendian
                    format = bin2dec(fliplr(char(bin + '0')));
                else
                    format = bin2dec(char(bin + '0'));
                end
            else
                format = reshape(bin, size(format));
            end
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
                        toconvert = reshape(hex(1+pointer*2:(pointer+nbytes)*2), bytesinelement*2, [])';
                    else
                        toconvert = reshape(hex((pointer-nbytes)*2+1:pointer*2), bytesinelement*2, [])';
                    end
                    if params.littleendian
                        %swap byte order (obfuscated one liner)
                        toconvert = reshape(flipdim(reshape(toconvert', 2, bytesinelement, []), 2), size(toconvert'))';
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
                        format(:) = hex2float(toconvert);
                    end
                else
                    error('frombytes:unsupportedDataType', 'Complex data not supported');
                end
            else
                error('frombytes:unsupportedDataType', 'Data type ''%s'' not supported', class(s));
            end
        end
    end


    function [format, nbytes] = frombytesblank(format, pointer, length, params)
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
            
            %read in bits, in the right order
            h = hex(floor(pointer)*2+1:ceil(pointer+length)*2);
            bits = dec2bin(hex2dec(h(:)), 4)' - '0';
            
            if (params.littleendian)
                %reverse bit order in bytes for this step...
                bits = reshape(flipud(reshape(bits, 8, [])), size(bits));
            end
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
            
            if params.littleendian
                %swap byte order (obfuscated one liner)
                h = reshape(flipdim(reshape(h', 2, bytesinelement, []), 2), size(h'))';
            end

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
                        format(dimsub{:}) = reshape(hex2float(toconvert), dims{:});
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