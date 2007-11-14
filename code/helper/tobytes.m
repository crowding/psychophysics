function bytes = tobytes(template, data, varargin)
    %Converts the arguments into a string of bytes using big-endian 
    %format and IEEE format for floats.
    %
    % The first argument gives the format of the data to be converted, and
    % the second gives the actual data. The format can have nested cells
    % and structs and the data should match that struct. Data is converted
    % according to the classes of data in the structure.
    %
    %Example:
    %
    % tobytes({double(0), single(0), uint16(0)}, {2.3 -1 258})
    % ans =
    %    64    2  102  102  102  102  102  102  191  128    0    0    1    2
    %
    % Here the first 8 bytes o the output express '2.3' as a double, the
    % next 4 bytes express -1 as a single, and the last express 258 as a
    % uint16.
    %
    % If the template and data contains a struct, the field order of the
    % template's struct will be followed. Example:
    %
    % tobytes...
    %     ( struct('first', uint8(0), 'second', uint8(0))...
    %     , struct('second', 2, 'first', 1) )
    % ans =
    %     1    2
    %
    % The size of numeric arrays must match between the template and the
    % data. If an empty array is provided in the template, data of any size
    % can be used.
    %
    % BITFIELDS:
    %
    % Logical arrays in the template will be packed 8 to a byte. Adjacent
    % logical arrays will be packed next to each other, but non-logical
    % arrays in the template must align to byte boundaries.
    % If the template has a bitfield but the data are integers, they will e
    % converted as unsigned integers. An error will be thrown if they are
    % out of range.
    %
    % Example:
    %
    % >> tobytes({logical([0 0 0 0]), logical([0 0 0 0])}, {4, 3})
    %ans =
    %   67
    %
    % Here, 67 = 0b01000011, which is 4 bits representing 4 followed by 4
    % bits representing 3.
    %
    % OPTIONS:
    %
    % If 'littleendian' is set to 1, values will be converted in network byte
    % order (LSB to MSB,) Bitfields and binary conversions will be filled
    % out LSB to MSB as well. If two bitfields overlap within a byte, The
    % first bitfield will fill the least significant bits of the
    % overlapping byte, and the second bitfield will fill the most
    % significant bits. These orders reverse if 'littleendian' is set to 0,
    % which is the default. 
    
    defaults = struct('littleendian', 0, 'enum', 1); %enum has no effect
    params = options(defaults, varargin{:});
    
    bytes = collapselogicals({tobytesstep(template, data, params)}, params);
end

function bytes = tobytesstep(template, in, params)

    if iscell(template)
        if iscell(in)
            
            out = cellfun(@(x, y)tobytesstep(x, y, params), template, in, 'UniformOutput', 0);
            bytes = out;
            return;
        else
            error('tobytes:unsupportedDataType', 'Data types ''%s'', ''%s'' not supported', class(template), class(in));
        end
    elseif isstruct(template)
        if numel(template) == 1
            if isfield(template, 'enum_') 
                if ischar(in)
                    if isfield(template, in)
                        bytes = tobytesstep(template.enum_, template.(in), params);
                    else
                        error('tobytes:noSuchValue', 'No such enum value');
                    end
                else
                    bytes = tobytesstep(template.enum_, in, params);
                end
            elseif isstruct(in)
                fns = fieldnames(template);

                if ~isempty(setdiff(fieldnames(in), fns))
                    error('tobytes:extraStructFields', 'Fields in data (%s) not in template (fields are %s)', join(', ', fieldnames(in)), join(', ', fns));
                end
                out = cell(size(fns))';
                for i = 1:numel(out)
                    if isfield(in, fns{i})
                        out{i} = tobytesstep(template.(fns{i}), in.(fns{i}), params);
                    else
                        out{i} = tobytesstep(template.(fns{i}), template.(fns{i}), params);
                    end
                end
                bytes = out;
            else
                error('tobytes:unsupportedDataType', 'Data types ''%s'', ''%s'' not supported', class(template), class(in));
            end
        else
            out = arrayfun(@(x,y)tobytesstep(x, y, params), template, in, 'UniformOutput', 0);
            bytes = out;
        end

        return;
    end
    
    tpl = template; tpl(1) = 0;
    element = tpl(1); %#ok
    s = whos('element');
    width = s.bytes;
    
    nd = ndims(in) + 1;
    [id{1:nd}] = size(template);
    
    if isstruct(in) && isfield(in, 'enum_')
        in = in.enum_;
    end
    
    if islogical(template) && isnumeric(in) && numel(in) == numel(template(1, :));
        %decimal to binary conversion ahoy.
        if any((in < 0)) | any((in >= 2^numel(template)))
            error('tobytes:outOfRange', 'data out of range for template');
        end
        bytes = logical(dec2bin(in, size(template, 1)) - '0');
        if params.littleendian
            bytes = fliplr(bytes);
        end
        bytes = reshape(bytes', size(template));
    elseif numel(in) ~= numel(template) && numel(template) ~= 0
        error('tobytes:wrongSize', 'data is the wrong size for template');
    elseif isnumeric(template) && isnumeric(in)
        if isreal(template) && isreal(in)
            if isinteger(template)
                c = class(template);
                mn = intmin(c);
                mx = intmax(c);
                if any(in < mn) | any(in > mx)
                    error('tobytes:outOfRange', 'data out of range for template');
                end
                
                if (mn < 0)
                    %signed data
                    adj = -2*double(mn);
                    in = double(in);
                    in(in < 0) = in(in < 0) + adj;
                end
                
                hex = dec2hex(in, width*2);
            else
                %float data
                in = cast(in, class(template));
                hex = num2hex(in);
            end
            
            if params.littleendian
                swapix = reshape(1:size(hex, 2), 2, []);
                swapix = fliplr(swapix);
                swapix = swapix(:)';
                hex = hex(:, swapix);
            end
        else
            error('tobytes:unsupportedDataType', 'Complex data not supported');
        end
        bytes = uint8(hex2dec(reshape(hex', 2, [])'))';
    elseif islogical(template)
        bytes = logical(in);
    else
        error('tobytes:unsupportedDataType', 'Data type ''%s'' not supported', class(in));
    end

end



function bytes = collapselogicals(in, params)
    subs = iteratesubs(in)';

    bytes = cell(size(subs));
    for i = 1:numel(bytes)
        bytes{i} = ssubsref(in, subs{i});
        bytes{i} = bytes{i}(:)';
    end

    l = cellfun('islogical', bytes);
    
    begins = find(diff([0 l]) > 0);
    ends = find(diff([l 0]) < 0);
    
    x = [128 64 32 16 8 4 2 1]';
    if (params.littleendian)
        x = flipud(x);
    end
    
    for i = [begins(:) ends(:)]'
        begin = i(1);
        en = i(2);
        
        %gather all the bits from this chunk of logical
        bits = false(1, sum(cellfun('prodofsize', bytes(begin:en))));
        ix = 0;
        for j = begin:en
            n = numel(bytes{j});
            bits(ix+1:ix+n) = bytes{j};
            ix = ix + n;
        end
        
        if mod(numel(bits), 8)
            error('tobytes:bitfieldWidth', 'Bitfields should be a multiple of 8 wide in total');
        end

        bits = reshape(bits, 8, []);
        %convert to bytes
        byte = uint8(sum(bits.*x(:, ones(1, size(bits, 2))), 1));
        bytes(begin:en) = {uint8([])};
        bytes{begin} = byte;
    end
    
    bytes = [bytes{:}];
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
