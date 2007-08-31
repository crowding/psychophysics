function varargout=num2IEEE(number,d)

% Syntax num2IEEE(number, d)
%
% NUMBER must be a valid double, a string representing a double, or expression which evaluates to a double
% D is optional and is the number of digits to use to display the result (requires the Symbolic Math Toolbox)
%
% With no outputs, this will display the number to d decimal places
% With 1 output argument, the 64-bit representation of the result will be returned
% With 3 output arguments, the first will be the sign bit, the second the exponent, and the third the mantissa
%
% Reference:  ANSI/IEEE Std 754-1985, section 3.2.2

% Possible enhancements:
%   Handle single precision data
%   Handle int* and uint* data types

if ~isstr(number)
    number=num2str(number);
end
OLD_FORMAT=get(0,'format');
set(0,'format','hex');
t=evalc(number);
set(0,'format',OLD_FORMAT);

t = t(find(t=='=')+1:end);
t = t(~(t==' ' | t==10));
r = zeros(size(t));

MaskDigits = (double(t)-'0');
Digits = MaskDigits(MaskDigits<10);
MaskLetters = (double(t)-'a');
Letters = MaskLetters(MaskLetters>=0)+10;

r(MaskDigits<10) = Digits;
r(MaskLetters>=0) = Letters;

s = dec2bin(r')';
s = s(:)'=='1';

sign=s(1)==1;
exponent=polyval(s(2:12),2);
mantissa=double(s(13:end));

if nargout<1
    
    if exponent==2047 & any(mantissa)
        disp('You entered NaN')
    elseif exponent==2047 & sign==1
        disp('You entered -Inf')
    elseif exponent==2047 & sign==0
        disp('You entered +Inf')
    elseif exponent==0 & ~any(mantissa)
        disp('You entered zero')
    else
        if isempty(ver('symbolic'))
            warning(sprintf('Sorry, you don''t have the Symbolic Math Toolbox.\nReturning 64 bit representation instead of displaying number.'))
            varargout{1}=s;
            return
        end
        E=sym('2^(-1)');
        M=1+(mantissa*E.^(1:52)');
        
        if exponent==0
            disp('You entered a denormalized number')
            M=2*(M-1);        
        end
        
        if nargin>1
            OLD_DIGITS=digits;
            digits(d);
        end
        
        N=((-1)^sign)*2^(exponent-1023)*M;
        fprintf('The number, to %d decimals, is:\n',digits)
        disp(vpa(N))
        
        if nargin>1
            digits(OLD_DIGITS)
        end
    end
    
elseif nargout<3
    varargout{1}=s;
else
    varargout{1}=sign;
    varargout{2}=logical(s(2:12));
    varargout{3}=logical(s(13:end));
end