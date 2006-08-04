function n = serialnumber
%returns a number which increments each time this function is called.

persistent sn;
if isempty(sn)
    sn = 1;
end

n = sn;
sn = sn + 1;
