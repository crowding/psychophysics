function hex = hexdump(bytes, blocklength, linelength)

    if (nargin < 3)
        linelength = 32;
    end
    if (nargin < 2)
        blocklength = 4;
    end

    hex = dec2hex(bytes, 2)';

    hex(end+1:linelength*2*ceil(numel(hex) / linelength/2)) = ' ';
    ns = numel(hex);
    hex = reshape(hex, linelength*2, []);
    class(hex);
    hex(end+1:blocklength*2*ceil(size(hex, 1) / blocklength/2), :) = ' ';
    hex = reshape(hex, blocklength*2, []);
    hex(end+1, :) = ' ';
    hex = reshape(hex, ceil(linelength/blocklength)*(blocklength*2+1), []);
    hex(end, :) = [];
    lineindices = [0:linelength:numel(bytes)-1]';
    labels = strcat(num2str(lineindices), ' (', dec2hex(lineindices), '):');
    hex = strvcat(labels', ' ', hex);
    
    hex = hex';
end