function data=dp_internal_unpack
% data=dp_internal_unpack
%
% Internal DP function.
% Unpack Matlab data from PVM receive buffer.

[info,type]=pvm_upkbyte(1,1); % unpack data type
switch type
    case 1
        data=dp_internal_unpack; % unpack numerical data
        data=sparse(data); % convert to sparse matrix
    case 2
        [info,ls]=pvm_upkbyte(1,1); % unpack number of dimensions
        [info,s]=pvm_upkint(ls,1); % unpack dimensions
        [info,rdata]=pvm_upkdouble(prod(s),1); % unpack real data
        [info,idata]=pvm_upkdouble(prod(s),1); % unpack imaginary data
        data=rdata+sqrt(-1)*idata; % create complex data
        data=reshape(data,s'); % reshape data
    case 3
        [info,ls]=pvm_upkbyte(1,1); % unpack number of dimensions
        [info,s]=pvm_upkint(ls,1); % unpack dimensions
        [info,data]=pvm_upkdouble(prod(s),1); % unpack numerical data
        data=reshape(data,s'); % reshape data
    case 4
        [info,ls]=pvm_upkbyte(1,1); % unpack number of dimensions
        [info,s]=pvm_upkint(ls,1); % unpack dimensions
        [info,data]=pvm_upkbyte(prod(s),1); % unpack character data
        data=reshape(data,s'); % reshape data
        data=char(data); % convert to character matrix
    case 5
        [info,ls]=pvm_upkbyte(1,1); % unpack number of dimensions
        [info,s]=pvm_upkint(ls,1); % unpack dimensions
        [info,data]=pvm_upkbyte(prod(s),1); % unpack logical data
        data=reshape(data,s'); % reshape data
        data=logical(data); % convert to logical data
    case 6
        [info,ls]=pvm_upkbyte(1,1); % unpack number of dimensions
        [info,s]=pvm_upkint(ls,1); % unpack dimensions
        data=cell(prod(s),1); % create cell array
        for j=1:prod(s)
            data{j}=dp_internal_unpack; % unpack cell
        end
        data=reshape(data,s'); % reshape data
    case 7
        fn=dp_internal_unpack; % unpack field names
        c=dp_internal_unpack; % unpack cell array data
        data=cell2struct(c,fn,1); % convert to structure
    otherwise
        error('Unsupported data type.');
end