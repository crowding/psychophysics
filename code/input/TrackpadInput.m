function this = TrackpadInput(varargin)
%reads input from the powerbook trackpad, correcting for a baseline.

device = [];

baselineH = zeros(1, 15) + 256;
rangeH = zeros(1, 15) + 16;
baselineV = zeros(1, 9) + 256;
rangeV = zeros(1, 9) + 16;

options = struct('secs', 0);

persistent init__;
this = autoobject(varargin{:});

    function d = discover()
        d = PsychHID('Devices');
        d = find(strcmp({d.product}, 'Trackpad'));
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
            error('TrackpadInput:noTrackpadFound', 'No device found');
        end
        
        baselineH = zeros(1, 15) + 256;
        baselineV = zeros(1, 9) + 256;
        
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

    function k = input(k)
        PsychHID('ReceiveReports', device, options);
        r = PsychHID('GiveMeReports', device);
        
        if ~isempty(r)
            hraw = double(r(end).report([20 21 23 24 26 27 29 30 32 33 35 36 38 39 41]));
            vraw = double(r(end).report([2 3 5 6 8 9 11 12 14]));
            
            baselineH = min(baselineH, hraw);
            baselineV = min(baselineV, vraw);
            rangeH = max(hraw - baselineH, rangeH);
            rangeV = max(vraw - baselineV, rangeV);
            
            hnorm = (hraw-baselineH)./rangeH;
            vnorm = (vraw-baselineV)./rangeV;
            
            %first moment of the norm...
            hmean = sum(hnorm .* (0:14)) ./ sum(hnorm);
            vmean = sum(vnorm .* (0:8)) ./ sum(vnorm);
                        
            %deviation...
            hdev = sqrt(sum(hnorm .* ((0:14)-hmean).^2) ./ sum(hnorm)) + 0.5;
            vdev = sqrt(sum(vnorm .* ((0:8)-vmean).^2) ./ sum(vnorm)) + 0.5;
            
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
