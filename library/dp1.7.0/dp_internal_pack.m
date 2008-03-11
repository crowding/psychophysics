function dp_internal_pack(data);
% dp_internal_pack(data)
%
% Internal DP function.
% Pack Matlab data into PVM send buffer.

if issparse(data)
    pvm_pkbyte(1,1); % pack data type
    dp_internal_pack(full(data)); % pack full double data
    return;
end

if isnumeric(data)
    s=size(data); % get data dimensions 
    if ~isreal(data)
        pvm_pkbyte(2,1); % pack data type
        pvm_pkbyte(length(s),1); % pack number of dimensions
        pvm_pkint(s,1); % pack dimensions
        pvm_pkdouble(real(data),1); % pack real data
        pvm_pkdouble(imag(data),1); % pack imaginary data
    else
        pvm_pkbyte(3,1); % pack data type
        pvm_pkbyte(length(s),1); % pack number of dimensions
        pvm_pkint(s,1); % pack dimensions
        pvm_pkdouble(data,1); % pack data
    end
    return;
end
    
if ischar(data)
    data=double(data); % convert to double matrix
    s=size(data); % get data dimensions
    pvm_pkbyte(4,1); % pack data type
    pvm_pkbyte(length(s),1); % pack number of dimensions
    pvm_pkint(s,1); % pack dimensions
    pvm_pkbyte(data,1); % pack character data
    return;
end

if islogical(data)
    data=double(data); % convert to double matrix
    s=size(data); % get data dimensions
    pvm_pkbyte(5,1); % pack data type
    pvm_pkbyte(length(s),1); % pack number of dimensions
    pvm_pkint(s,1); % pack dimensions
    pvm_pkbyte(data,1); % pack logical data
    return;
end

if iscell(data)
    s=size(data); % get data dimensions
    pvm_pkbyte(6,1); % pack data type
    pvm_pkbyte(length(s),1); % pack number of dimensions
    pvm_pkint(s,1); % pack dimensions
    for j=1:prod(s)
        dp_internal_pack(data{j});
    end
    return;
end

if isstruct(data)
    pvm_pkbyte(7,1); % pack data type
    fn=fieldnames(data); % get field names
    dp_internal_pack(fn); % pack field names (cell array)
    c=struct2cell(data); % convert structure to cell array
    dp_internal_pack(c); % pack cell array
    return;
end

error('Unsupported data format.');
