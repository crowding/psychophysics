function h = hex2float(chars)
    %like hex2num, but allows for 32-bit floats. Input must be a char array
    %either 8 or 16 columns.
    
    switch size(chars, 2)
        case 8
            %doubles have a sign, 11 exponent and 52 mantissa.
            %SEEE EEEE EEEE MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM MMMM
            %singles have a sign, 8 exponent and 23 mantissa.
            %SEEE EEEE EMMM MMMM MMMM MMMM MMMM MMMM
            
            %quickest I think just to interpret IEEE 754 directly rather
            %than trying to repack in into a double precision...
            ints = hex2dec(chars);
            
            sign = ints >= uint32(2147483648); % 0x80000000
            exp = bitshift(bitand(ints, 2139095040), -23); %0xFf800000
            mant = bitand(ints, 8388607); %0x007FFFFF
            
            norm = exp > 0; %normalized numbers
            
            %actual translation...
            h = (mant./(2.^23)+norm) .* 2.^(exp - 126 - norm);
            h(exp == 255 & mant == 0) = Inf;
            h(exp == 255 & mant ~= 0) = NaN;
            h(sign) = -h(sign);
        case 16
            %the 64 bit flaot is handled by hex2num
            h = hex2num(chars);
        otherwise
            error('hex2float:wrongDataSize', 'wrong data size for hex2float');
    end
end