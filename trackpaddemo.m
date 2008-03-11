d = 4;
FlushEvents(); %for charAvail
options = struct('secs', 0);
bv = zeros(1, 9) + 256;
bh = zeros(1, 15) + 256;

%sound = 
while ~CharAvail
    PsychHID('ReceiveReports', d, options);
    r = PsychHID('GiveMeReports', d);
    if ~isempty(r)
        rep = r(end).report;
        
        %these values seem to give capacitance readings from the
        %trackpad
        v = double(rep([2 3 5 6 8 9 11 12 14]));
        h = double(rep([20 21 23 24 26 27 29 30 32 33 35 36 38 39 41]));
        
        bh = min(h, bh);
        bv = min(v, bv);
        
        x = (h - bh); y = (v - bv);
        
        image(sqrt(y' * x));
        drawnow;
    end
end

%do an ifft of the vertical...
%fill the buffer up to 20ms from now with ifft'd verticals