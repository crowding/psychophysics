function this = TrackpadInput(varargin)
%reads input from the powerbook trackpad, correcting for a baseline.
%tested on powerbook g4 and macbook pro trackpads...

device = [];

baselineH = zeros(1, 15) + 256;
rangeH = zeros(1, 15) + 16;
baselineV = zeros(1, 9) + 256;
rangeV = zeros(1, 9) + 16;

options = struct('secs', 0);
decoder_ = @decoder532;

persistent init__;
this = autoobject(varargin{:});

    function d = discover()
        d = PsychHID('Devices');
        d = find((strcmp({d.product}, 'Trackpad') & ([d.productID] == 532)) | (strcmp({d.usageName}, 'Mouse') & ([d.productID] == 538)));
        if ~isempty(d)
            d = d(2);
            if isempty(device)
                device = d;
            end
        end
    end

    offset_ = [0 0];
    gain_ = eye(2);
    function [release, params] = init(params)
        if isempty(device)
            device = discover();
        end
        
        if isempty(device)
            error('TrackpadInput:noTrackpadFound', 'No compatible trackpad device found');
        end
        
        %but which model trackpad?
        d = PsychHID('Devices');
        switch d(device).productID
            case 532 %trackpad on Powerbook G4
                baselineH = zeros(1, 15) + 256;
                baselineV = zeros(1, 9) + 256;
                rangeH = zeros(1, 15) + 16;
                rangeV = zeros(1, 9) + 16;

                decoder = @decoder532_;
                
            case 538 %trackpad on MacBook Pro (non-multitouch)
                baselineH = zeros(1, 20) + 4096;
                baselineV = zeros(1, 10) + 4096;
                rangeH = zeros(1, 20) + 16;
                rangeV = zeros(1, 10) + 16;
                decoder_ = @decoder538_;
            otherwise
                error('TrackpadInput:unknownDevice', 'I don''t know what kind of trackpad this is (productID %s)', d(device).productID);
        end
        
        release = @r;
        function r()
            %do nothing
        end
        
        %the coordinates will be scaled to the screen...
        t = transformToDegrees(params.cal);
        rect = t(params.rect);
        offset_ = [-7 -4];
        gain_ = diag( (rect([3 4]) - rect([1 2])) ./ [14 8]);
    end

    function [release, params] = begin(params)
        PsychHID('GiveMeReports', device);
        PsychHID('ReceiveReports', device, options);

        release = @r;
        function r()
            PsychHID('ReceiveReportsStop', device);
            r = PsychHID('GiveMeReports', device);
        end
    end

    function sync(refresh, when)
        %nothing needed
    end

    function [h, v] = decoder532_(report)
        h = double(report([20 21 23 24 26 27 29 30 32 33 35 36 38 39 41]));
        v = double(report([2 3 5 6 8 9 11 12 14]));
    end

    function [h, v] = decoder538_(report)
        high_odd = double(bitand(report([2 5 8 11 14 20 23 26 29 32 35 38 41 44 47]), uint8(240))) * 16;
        high_even = double(bitand(report([2 5 8 11 14 20 23 26 29 32 35 38 41 44 47]), uint8(15))) * 256;
        high = [high_odd;high_even];

        %then horizontal axis readings are...
        h = double(report([21 22 24 25 27 28 30 31 33 34 36 37 39 40 42 43 45 46 48 49])) + high(11:30);
        %twos compliment;
        %h = mod(h + 2048, 4096)-2048;
        %and vertical...
        v = double(report([3 4 6 7 9 10 12 13 15 16])) + high(1:10);
    end

    function k = input(k)
        PsychHID('ReceiveReports', device, options);
        r = PsychHID('GiveMeReports', device);
        
        if ~isempty(r)
            [hraw, vraw] = decoder_(r(end).report);
            
            baselineH = min(baselineH, hraw);
            baselineV = min(baselineV, vraw);
            rangeH = max(hraw - baselineH, rangeH);
            rangeV = max(vraw - baselineV, rangeV);

            hnorm = (hraw-baselineH)./rangeH;
            vnorm = (vraw-baselineV)./rangeV;
            
            %first moment of the norm...
            hmean = sum(hnorm .* (0:numel(hnorm)-1)) ./ sum(hnorm);
            vmean = sum(vnorm .* (0:numel(vnorm)-1)) ./ sum(vnorm);
                        
            %deviation...
            hdev = sqrt(sum(hnorm .* ((0:numel(hnorm)-1)-hmean).^2) ./ sum(hnorm)) + 0.5;
            vdev = sqrt(sum(vnorm .* ((0:numel(vnorm)-1)-vmean).^2) ./ sum(vnorm)) + 0.5;
            
            %"amplitude"
            hamp = sum(hnorm) / hdev;
            vamp = sum(vnorm) / vdev;
            
            k.trackpadHraw = hraw;
            k.trackpadVraw = vraw;
            k.trackpadH = hnorm;
            k.trackpadV = vnorm;
            if all(~isnan([hmean vmean]))
                noop()
            end
            k.trackpadLoc = ([hmean, vmean] + offset_) * gain_;
            k.trackpadSize = abs([hdev, vdev] * gain_);
            k.trackpadAmp = [hamp, vamp];
            k.trackpadT = r(end).time;
        end
    end
end
