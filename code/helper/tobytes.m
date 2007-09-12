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
    % tobytes also supports struct and cell arguments, and will iterate
    % through structure fields in order.
    %
    % Logical arrays will be packed, but must be a multiple of 8 values
    % wide. You can split a logical array across structs or cells to meet
    % this requirement.
    %
    % if you give the first argument of 'template', argument 2 is the
    % template, and argument 3 is the atruct/cell/array to be converted.
    %
    % BITFIELDS:
    % 
    % Some handling for bitfields. If a struct or cell template is composed
    % of logicals, then scalar arguments in the data will be translated
    % into bits of the appropriate size. Contiguous bitfields must add up
    % to a whole number of bytes. For example:
    %
    % >> tobytes('template', {logical([0 0 0 0]), logical([0 0 0 0])}, {4, 3})
    %ans =
    %   67
    %
    
    if isequal(varargin{1}, 'template')
        bytes = collapselogicals({tobytesstep(varargin{2}, varargin{3})});
    else
        out = cellfun(@tobytesstep, varargin, varargin, 'UniformOutput', 0);
        %handle logicals
        bytes = collapselogicals(out);
    end
end

function bytes = tobytesstep(template, in)
    element = template(1:min(1, numel(template))); %#ok
    s = whos('element');
    width = s.bytes;
    
    if islogical(template) && isnumeric(in) && isscalar(in)
        %decimal to binary conversion ahoy.
        bytes = logical(dec2bin(in, numel(template)) - '0');
        if numel(bytes) ~= numel(template)
            error('tobytes:outOfRange', 'data out of range for template');
        end
        
    elseif numel(in) ~= numel(template)
        error('tobytes:wrongSize', 'data is the wrong size for template');

    elseif isnumeric(template) && isnumeric(in)
        if isreal(template) && isnumeric(in)
            if isinteger(template)
                if any(in < 0) %signed data
                    adj = -2*double(intmin(class(template)));
                    in = double(in);
                    in(in < 0) = in(in < 0) + adj;
                end
                hex = dec2hex(in, width*2);
                if (size(hex, 2) ~= width*2)
                    error('tobytes:outOfRange', 'data out of range for template');
                end
            else
                in = cast(in, class(template));
                hex = num2hex(in);
            end
        else
            error('tobytes:unsupportedDataType', 'Complex data not supported');
        end
        bytes = uint8(hex2dec(reshape(hex, 2, [])'))';
    elseif islogical(template)
        bytes = logical(in);
    elseif iscell(template) && iscell(in);
        out = cellfun(@tobytesstep, template, in, 'UniformOutput', 0);
        bytes = collapselogicals(out);
        return;
    
    elseif isstruct(template) && isstruct(in)
        in = orderfields(in, template);
        in = struct2cell(in)';
        template = struct2cell(template)';
        out = cellfun(@tobytesstep, template, in, 'UniformOutput', 0);
        bytes = collapselogicals(out);
        return;
    else
        error('tobytes:unsupportedDataType', 'Data type ''%s'' not supported', class(in));
    end

end



function bytes = collapselogicals(in)
    l = cellfun('islogical', in);
    
    begins = find(diff([0 l]) > 0);
    ends = find(diff([l 0]) < 0);

    x = [128 64 32 16 8 4 2 1]';

    for i = [begins(:) ends(:)]'
        begin = i(1);
        en = i(2);
        bits = cat(2, in{begins:ends});
        if mod(numel(bits), 8)
            error('tobytes:bitfieldWidth', 'Bitfields should be a multiple of 8 wide in total');
        end

        bits = reshape(bits, 8, []);
        %convert to bytes
        bytes = uint8(sum(bits.*x(:, ones(1, size(bits, 2))), 1));
        in(begin:en) = {uint8([])};
        in{begin} = bytes;
    end
    
    bytes = [in{:}];
end
