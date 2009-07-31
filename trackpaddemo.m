d = 4;
FlushEvents(); %for charAvail
options = struct();
bv = zeros(1, 10) + 4096;
bh = zeros(1, 20) + 4096;

%the format of the trackpad status string
backlog = [];d
%sound = 
while ~CharAvail
    PsychHID('ReceiveReports', d, options);
    r = PsychHID('GiveMeReports', d);
    if ~isempty(r)
        rep = r(end).report;
        bits = double(frombytes(rep,false(1, 512)));
        
        %this turns out to be quite jumbled. High nibble of byte 2
        %followed by byte 3 = first capacitor reading. Low nibble of byte
        %1 followed by byte 4 = second capacitor reading. And so on, two
        %readings per 3 bytes. The vertical axis is read from bytes 2-16,
        %and horizontal from 20-49.
        high_odd = double(bitand(rep([2 5 8 11 14 20 23 26 29 32 35 38 41 44 47]), uint8(240))) * 16;
        high_even = double(bitand(rep([2 5 8 11 14 20 23 26 29 32 35 38 41 44 47]), uint8(15))) * 256;
        high = [high_odd;high_even];

        %then horizontal axis readings are...
        h = double(rep([21 22 24 25 27 28 30 31 33 34 36 37 39 40 42 43 45 46 48 49])) + high(11:30);
        %twos compliment;
        %h = mod(h + 2048, 4096)-2048;
        %and vertical...
        v = double(rep([3 4 6 7 9 10 12 13 15 16])) + high(1:10);
        %v = mod(v + 2048, 4096)-2048;

        bh = min(bh, h); bv = min(bv, v);
        x = (h - bh); y = (v - bv);

        backlog = [backlog(max(end-64, 1):end, :);bits];
        
        [a, b] = ndgrid(y, x);
        image((a+b));

        drawnow;
    end
end

%do an ifft of the vertical...
%fill the buffer up to 20ms from now with ifft'd verticals