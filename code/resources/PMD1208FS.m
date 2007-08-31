function this = PMD1208FS(varargin)
    %Object that interfaces to the PMD1080FS. As of now it only supports
    %executing regularly sampled AInScan operations. 
    
    %constants

    VMAX_ = [20,10,5,4,2.5,2,1.25,1]; %gain levels and the max voltages
                                      %they correspond to.

    %------ properties ------
    
    device = [];
    serialNumber = [];  %the serial number of the DAQ
    
    options = struct ...
        ( 'count', Inf ...
        , 'channel', [0] ...
        , 'range', [0] ...
        , 'f', 1000 ...
        , 'immediate', 0 ...
        , 'trigger', 0 ...
        , 'secs', 0 ... %A value of 0 here seems to gather all incoming
                    ... %reports just fine, including when multiple
                    ... %reports have arrived since the last call; any
                    ... %nonzero value would just waste time.
        , 'print', 0 ...
        );

    open = 0;
    AInScanRunning = 0;

    maxBacklog = 10000;  %how many samples to keep in the backlog before
                         %dropping them.
    
    maxOutOfSync = 0.01; %if sync drifts by more than this many seconds,
                         %issue a warning at the end of an AInScan.
    
    %calibration bobbins
    CALIBRATION_MAGIC_NUMBER_ = uint16(57826); %arbitrary magic number
    CALIBRATION_ADDRESS_ = 512; %beginning of user data region
    CALIBRATION_FORMAT_ = {uint16(1), uint32(1), 1, zeros(1,8), zeros(1,8)};

    calibrationDate = uint32(0);    %When calibration was performed (serial date number)
    clockDrift = 0;                 %Clock adjustment. How quickly the PMD's clock drifts relative to the
                                    %computer's (extra seconds of PMD time per second of computer time.)
    gainAdj = ones(size(VMAX_));    %the gain adjustment, per gain level.
    offsetAdj = zeros(size(VMAX_)); %the offset adjustment, per gain level.
    
    %private
    dinc_ = []; %increment to find the PMD's three data interfaces
    
    %------ instantiation ------
    
    this = autoobject(varargin{:});
    
    %do initialization on creation
    initialize_();
    
    
    function initialize_()
        if isempty(device)
            if isempty(serialNumber)
                device = deviceIndex;
                serialNumber = querySerialNumber();
            else
                device = deviceIndex(serialNumber);
            end
        else
            if isempty(serialNumber)
                serialNumber = querySerialNumber();
            else
                if ~isequal(serialNumber, querySerialNumber)
                    %we get here if both device index and serial number were
                    %specified. Trust the serial number.
                    d = deviceIndex(serialNumber);
                    if ~isequal(d, device)
                        warning('PMD1208FS:deviceIndexMismatch', 'Device index does not match device.');
                    end
                end
            end
        end

        if isempty(device)
            error('PMD1208FS:deviceNotFound', 'Device not found. Perhaps try using %s(''reset'', 1)', mfilename);
        end
        
        device = device(1);

        devices=PsychHID('Devices');
        for dinc_=[-1 1]
            if device+dinc_>=1 && device+dinc_<=length(devices) && (devices(device+dinc_).outputs==65 || devices(device+dinc_).outputs==1)
                break
            else
                dinc_=[];
            end
        end

        if devices(device).outputs<70 || isempty(dinc_) || ~streq(devices(device).serialNumber,devices(device+dinc_).serialNumber)
            error('PMD1208FS:invalidDevice', 'Invalid device, not the original USB-1208FS.');
        end
        
        AInStop_();
        AOutStop_();
        
        %finally load the calibration from device memory
        readCalibration();
    end



    %------ methods ------
    
    
    
    function daq = deviceIndex(serialNumber)
        %returns a list of all your PMD devices, or if you specify a
        %serial number parameter, searches for that particular device.
        devices=PsychHID('Devices');
        daq=[];
        for i=1:length(devices)
            product=devices(i).product;
            if (streq(product,'PMD-1208FS')|streq(product,'USB-1208FS')) & devices(i).outputs>=70
                if (nargin < 1) || isequal(devices(i).serialNumber, serialNumber)
                    daq(end+1)=i;
                end
            end
        end
    end



    function sn = querySerialNumber()
        d = PsychHID('Devices');
        sn = d(device).serialNumber;
    end



    function [release, params] = init(params)
        assertNotOpen_();
            
        % The user supplies us only the device index "device" corresponding to
        % interface 0. The reports containing the samples arrive on interfaces
        % 1,2,3. As returned by PsychHID('Devices'), interface "i" is at
        % device-i, and we proceed on that basis after doing a quick check to
        % confirm our assumption. However, to be platform-independent, it would
        % be better to actually find all four device interfaces and confirm
        % their interface numbers. USB Probe reports interface numbers, but, as
        % far as I can tell, Apple's HID Explorer and our PsychHID do not
        % return this information. However, PsychHID('Devices') does report the
        % number of outputs: the USB-1208FS interface 0 has 229 (pre-Tiger) 70 (Tiger) outputs,
        % interface 1 has 65 (pre-Tiger) 1 (Tiger) outputs, and interfaces 2 and 3 have zero outputs.
        % I have no idea why the number of outputs changed with the arrival of Mac OS X Tiger.
        
        AInStop_();
        AOutStop_();
        
        err=DaqALoadQueue(device,options.channel,options.range);
        if err.n
            fprintf('DaqALoadQueue error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
        end
        
        open = 1;
        release = @release_;
        
        function release_()
            AInStop_();
            AOutStop_();
            open = 0;
        end
    end



    function setOpen(o)
        if ~isequal(o, open)
            error('PMD1208FS:illegalOperation', 'need to initialize with require(device.init(), @code)');
        end
    end



    function setAInScanRunning(o)
        if ~isequal(o, AInScanRunning)
            error('PMD1208FS:illegalOperation', 'read only value');
        end
    end



    function setOptions(o)
        if open
            error('PMD1208FS:illegalOperation', 'can''t change options while open');
        end
        
        %validate options
        o = namedargs(options, o);
        [o, q] = interface(options, o);
        if ~isempty(fieldnames(q{1}))
            error('PMD1208FS:illegalValue', 'Unknown PMD option(s) %s.', join(', ', fieldnames(q{1})));
        end
        
        %validate options contents
        %---------------
        
        %channel
        if isempty(o.channel) || isempty(o.range)
            error('PMD1208FS:illegalArgument', '"options.channel" and "options.range" vectors must be specified');
        end
        if length(o.channel)~=length(o.range)
            error('PMD1208FS:illegalArgument', '"options.channel" and "options.range" vectors must be of the same length.');
        end
        if any(o.channel < 0 | o.channel > 15)
            error('PMD1208FS:illegalArgument', '"options.channel"  must be 0-15.');            
        end
        if any(o.range < 0 | o.range >= length(VMAX_))
            error('PMD1208FS:illegalArgument', '"options.range"  out of bounds.');            
        end
        c=length(o.channel);

        %count
        o.count = round(o.count);
        if ~isinf(o.count) && ((o.count < 0) || (o.count*c > intmat('uint32')))
        	error('PMD1208FS:illegalArgument', 'options.count is out of 32-bit range, yet not INF.');
        end
        
        %f
        nF = nearestF(o.f, o.channel);
        if abs(log10(nF/o.f))>log10(1.1)
            error('PMD1208FS:badFrequency', 'Nearest attainable sampling frequency %.4f kHz is too far from requested %.4f kHz.',params.fActual/1000,o.f/1000);
        end
        
        options = o;
    end



    function [fActual ,prescale, preload, fNominal] = nearestF(f, channel)
        %computes the nearest available sampling frequency to the desired
        %one, as well as low-level prescale and preload parameters. Pass
        %the channel argument for the nearest frequency under a particular
        %channel scan sequence (otherwise the present one will be used)
        
        if nargin < 2
            channel = options.channel;
        end
        
        
        f = f * numel(channel) / (1+clockDrift);
        prescale=ceil(log2(10e6/65535/f)); % Use smallest integer timer_prescale consistent with pmd.f.
        prescale=max(0,min(8,prescale)); % Restrict to available range.
        preload=round(10e6/2^prescale/f);
        preload=max(1,min(65535,preload)); % Restrict to available range.
        fNominal = 10e6/2^prescale/preload / numel(channel);
        fActual = fNominal + fNominal * clockDrift;
    end



    %private state variables used during an AInScan()
    fActual_ = [];
    fNominal_ = [];
    tBegin_ = [];
    tFirstPacket_ = [];
    lastserial_ = [];

    incompleteSamples_ = [];
    incompleteChannels_ = [];
    incompleteData_ = [];
    
    warnDataLoss_ = 0;
    warnSyncLoss_ = 0;
    
    wrapping_ = 0;
    serialOffset_ = 0;
    
    function AInScanBegin(tBegin)
        if (nargin >= 1)
            tBegin_ = tBegin;
        else
            tBegin_ = 0;
        end
        
        tFirstPacket_ = [];
        lastserial_ = [];

        incompleteSamples_ = [];
        incompleteChannels_ = [];
        incompleteData_ = [];

        warnDataLoss_ = 0;
        warnSyncLoss_ = 0;
        
        wrapping_ = 0;
        serialOffset_ = 0;

        if ~open
            error('PMD1208FS:notInitialized', 'need to initialize with require(device.init(), @code)');
        end
        
        %build the report to begin scan.s. The channel queue is already
        %loaded by open();
        c = numel(options.channel);
        [fActual_, timer_prescale, timer_preload, fNominal_] = nearestF(options.f);
        
        if isfinite(options.count)
            counted = 1;
            count = uint32(c * options.count);
        else
            counted = 0;
            count = uint32(0);
        end
        
        report=uint8(zeros(1,11));
        report(1)=17;
        report(2)=0;
        report(3)=0;
        report(4)=bitand(count,255); % count
        report(5)=bitand(bitshift(count,-8),255);
        report(6)=bitand(bitshift(count,-16),255);
        report(7)=bitand(bitshift(count,-24),255);
        report(8)=timer_prescale; % timer_prescale
        report(9)=bitand(timer_preload,255); % timer_preload
        report(10)=bitshift(timer_preload,-8);
        report(11)=counted+2*options.immediate+4*options.trigger+16;
        PsychHIDCheckError_('SetReport',device,2,17,report); % AInScan
        AInScanRunning = 1;
    end



    function [data, t, latest, sync] = AInScanSample()
        if ~AInScanRunning
            error('PMD1208FS:illegalOperation', 'need to start scan before sampling');
        end

        %return samples and nominal time since start
        reports = [];
        %if options.secs is zero, loop until we have everything
        for d = (1:3)*dinc_
            err = PsychHID('ReceiveReports', device+d, options); %options.print
            if err.n
                error('PMD1208FS:PsychHIDError','%s error 0x%s. %s: %s\n', varargin{1}, hexstr(err.n),err.name,err.description);
            end

            [r, err] = PsychHID('GiveMeReports', device+d);
            if err.n
                error('PMD1208FS:PsychHIDError','%s error 0x%s. %s: %s\n', varargin{1}, hexstr(err.n),err.name,err.description);
            end

            reports = [reports r];
        end
        
        if ~isempty(reports)
            
            if isempty(tFirstPacket_)
                tFirstPacket_ = min([reports.time]);
            end
            
            c = numel(options.channel);

            %TODO: Handle count/retrigger options (i.e. don't report
            %past-the-count data as being samples, and find out whether
            %retriggering starts a new packet -- at present it looks as if
            %my PMD-1208FS doesn't support the retrigger option so this is a
            %moot point.
            
            if (options.immediate)
                bytes = 2;
                samplesPer = 1;
            else
                bytes = 62;
                samplesPer = 31;
            end

            %aggregate all the reports one per column
            alldata = double(cat(1, reports.report)');
            
            %each column contains a serial number
            serials = alldata(63,:)+256*alldata(64,:);
            
            %combine samples as SIGNED shorts, scaling to the range [-1..1)
            data = (alldata(1:2:bytes, :) + alldata(2:2:bytes, :)*256);
            data = (data-(65536*(data>=32768))) ./ 32768;

            %Deal with wraparound of the packet serial number.
            if (max([serials lastserial_]) >= (65535-ceil(maxBacklog/samplesPer)-numel(reports))) && (min([serials lastserial_]) <= (ceil(maxBacklog/samplesPer))+numel(reports))
                serials(serials<=32768) = serials(serials<=32768) + 65536;
                lastserial_ = max(serials) - 65536;
                wrapping_ = 1;
            else
                lastserial_ = max(serials);
                if wrapping_
                    %advance the clock...
                    serialOffset_ = serialOffset_ + 65536;
                    wrapping_ = 0;
                end
            end
            
            serials = serials + serialOffset_;

            
            %Note that I use a double values that keep increasing to count
            %samples. The smallest positive integer not representable in a
            %double is 2^53 + 1; at 50000 samples/sec, it should take a few
            %thousand years before this runs into problems.
            
            %Now, the device just gives us a stream of data. Which channels and
            %sample numbers does each number correspond to?

            %which (zero-based) channel index for each bit of data?
            %slow: [plus, channels] = ndgrid((0:samplesPer-1)', mod(samplesPer, c) * serials);
            %faster:
            plus = (0:samplesPer-1)';
            plus = plus(:, ones(1,numel(serials)));
            channels = serials(ones(samplesPer, 1), :)*mod(samplesPer, c);
            
            channels = mod(channels + plus, c);

            %which (zero-based) sample index for each bit of data?
            %slow: [plus, samples] = ndgrid((0:samplesPer-1)', samplesPer * serials);
            %faster:
            samples = serials(ones(samplesPer, 1),:)*samplesPer;
            plus = (0:samplesPer-1)';
            plus = plus(:, ones(1,numel(serials)));
            
            samples = floor((samples + plus) / c);
            
            %mix in incomplete data from previous runs
            data = [incompleteData_(:); data(:)];
            samples = [incompleteSamples_(:); samples(:)];
            channels = [incompleteChannels_(:); channels(:)];

            %assemble the samples we have...
            firstSample = min(samples);
            lastSample = max(samples);

            %we can't keeep backlogged samples around forever.
            if lastSample >= firstSample+maxBacklog
                warnDataLoss_ = 1;
                firstSample = lastSample - maxBacklog + 1;
                keep = samples > firstSample;
                data = data(keep);
                channels = channels(keep);
                samples = samples(keep);
            end
            
            
            %now arrange these samples as an array...
            assembled = zeros(c, (lastSample-firstSample) + 1) + NaN;
            
            %assembled(sub2ind(size(assembled), channels+1, samples - firstSample + 1)) = data;
            assembled(channels+1 + size(assembled, 1)*(samples - firstSample)) = data;

            
            samples = (firstSample:lastSample);
            times = samples / fNominal_;
            times = times + (times*clockDrift) + tBegin_;
            
            %Inspect for the discrepancy of time packets received versus
            %time indicated.
            latest = max([reports.time]);
            
            sync = (max(times) - tBegin_ + (samplesPer-1)/c/fActual_) ...
                 - (latest - tFirstPacket_);
             
            if abs(sync) > maxOutOfSync
                warnSyncLoss_ = 1;
            end

            if abs(sync) > 1
                noop(); %something fishy gong on
            end

            %these samples are good, forward them on
            bf = ~isnan(assembled);
            good = all(bf, 1);
            bf(:,good) = 0; %bitfield shows incomplete samples
            
            data = assembled(:,good);
            [t, i] = sort(times(good));
            data = data(:,i);
            
            %deal with the incomplete samples (hold them over)
            [channelix, sampleix] = find(bf);
            incompleteSamples_ = sampleix + firstSample - 1;
            incompleteChannels_ = channelix - 1;
            incompleteData_ = assembled(bf);
            
            %FINALLY, apply the gain adjustments
            offsets = offsetAdj(options.range(:) + 1);
            offsets = offsets(:);
            gains = gainAdj(options.range(:) + 1);
            gains = gains(:) .* VMAX_(options.range(:) + 1)';
            
            data = (data + offsets(:, ones(1, size(data, 2)))) ...
                   .* gains(:, ones(1, size(data, 2)));
        else
            %keeping zero dimension arrays dimensions consistent is
            %nice
            data = zeros(numel(options.channel), 0);
            t = zeros(1, 0);
            latest = zeros(0, 1);
            sync = zeros(0, 1);
        end
    end


    function r = vmax()
        %returns the range for each channel.
        r = VMAX_(options.range(:) + 1)';
    end


    function [lostdata] = AInStop()
        %Stop the scan and return
        if ~open
            error('PMD1208FS:notInitialized', 'need to initialize with require(device.init(), @code)');
        else
            AInStop_();
        end
        if (warnDataLoss_)
            warning('PMD1208FS:lostData', 'Packet serial numbers indicated data loss during the scan');
            lostdata = 1;
        else
            lostdata = 0;
        end
        if warnSyncLoss_
             warning('PMD1208FS:outOfSync', 'Timing of packet receipt drifted out of sync with sample count. Consider calibrating the clock on this device.');
        end
    end

    function AInStop_()
        %private function, doesn't care whether we're open
        PsychHIDCheckError_('SetReport',device,2,18,uint8(0));

        flush_();

        for d=(1:3)*dinc_
            PsychHIDCheckError_('ReceiveReportsStop',device+d);
        end
    end



    function flush_()
        % Flush any stale reports.
        for d=(1:3)*dinc_ % Interfaces 1,2,3
            PsychHIDCheckError_('ReceiveReports',device+d);
        end
        
        for d=(1:3)*dinc_ % Interfaces 1,2,3
            reports=PsychHIDCheckError_('GiveMeReports',device+d);
            if ~isempty(reports) && options.print
                fprintf('Flushing %d stale reports from device %d.\n',length(reports),device+d);
            end
        end
    end



    function AOutStop()
        if ~open
            error('PMD1208FS:notInitialized', 'need to initialize with require(device.init(), @code)');
        else
            AOutStop_();
        end
    end

    function AOutStop_()
        %Private version, does not check if device is open.
        PsychHIDCheckError_('SetReport',device,2,22,uint8(0));
    end



    function reset()
        if open
            error('PMD1208FS:illegalOperation', 'can''t reset while open');
        end

        fprintf('Resetting USB-1208FS.\n');
        clear PsychHID; % flush current enumeration (list of devices)
        WaitSecs(1); %don't know why this is necessary
        reacquire();

        % Reset. Ask the USB-1208FS to reset its USB interface.
        PsychHIDCheckError_('SetReport',device,2,65,uint8(65)); % Reset
        
        % CAUTION: Immediately after RESET, all commands fail, returning error
        % messages saying the command is unsupported (0xE00002C7) or the device is
        % not responding (0xE00002ED) or not attached (0xE00002D9). To restore
        % communication we must flush the current enumeration and re-enumerate the
        % HID-compliant devices.
        
        clear PsychHID; % flush current enumeration  (list of devices)
        WaitSecs(1); %don't know why this is necessary, again
        reacquire();
    end



    function reacquire()
        %Try to find the device number again.
        assertNotOpen_();
        
        daq=deviceIndex(serialNumber);
        if isempty(daq)
            device = [];
            error('Sorry, couldn''t find a USB-1208FS.');
        end
        if ~any(ismember(device,daq))
            warning('PMD1108FS:deviceIndexChanged', 'The device index changed from %d to %d', device, daq(1));
            device=daq(1);
        end
    end



    function writeCalibration()
        %store the calibration coefficients on device memory.
        data = {CALIBRATION_MAGIC_NUMBER_, calibrationDate, clockDrift, offsetAdj, gainAdj};
        for i = 1:numel(data)
            if numel(data{i}) ~= numel(CALIBRATION_FORMAT_{i})
                error('PMD1208FS:calibrationNotWritten', 'Calibration properties are of the wrong size');
            end
            data{i} = cast(data{i}, class(CALIBRATION_FORMAT_{i}));
        end
        
        bytes = tobytes(data{:});
        
        for i = 0:59:numel(bytes)
            len = min(59, numel(bytes)-i);
            memWrite(CALIBRATION_ADDRESS_ + i, bytes(i+1:i+len));
            verify = memRead(CALIBRATION_ADDRESS_ + i, len);
            if ~isequal(verify, bytes(i+1:i+len))
                error('PMD1208FS:CalibrationWriteError', 'Could not write the calibration data.');
            end
        end
    end



    function [drift, int, stats] = calibrateClock(samples, f)
        %tries to calibrate the PMD's clock and return a drift rate,
        %confidence interval, and stats
        if (nargin < 1)
            samples = 100000;
        end
        if (nargin < 2)
            f = 1000;
        end
        
        y = zeros(samples, 1);
        x = zeros(samples, 1);
        require(@saveoptions, highPriority(), @init, @gatherSamples);

        function [release, params] = saveoptions(params)
            tmpoptions = options;
            tmpClockDrift = clockDrift;
            clockDrift = 0;
            this.setOptions(struct('f', f, 'channel', 0, 'range', 0, 'immediate', 1, 'secs', 0, 'trigger', 0, 'print', 0));
            release = @r;
            function r
                options=tmpoptions;
                clockDrift=tmpClockDrift;
            end
        end
        
        function gatherSamples
            i = 1;
            ns = 0;
            begin = GetSecs;
            latestlatest = begin;
            AInScanBegin(GetSecs + 0.014); %setup time
            while(i <= samples)
                [data, t, latest, sync] = AInScanSample();
                ns = ns + size(data, 2);
                if ~isempty(latest)
                    x(i) = latest;
                    y(i) = sync;
                    i = i + 1;
                    latestlatest = latest;
                end
                if (GetSecs - latestlatest > 1)
                    error('PMD1208FS:notGettingSamples', 'not receiving samples');
                end
            end
            warnSyncLoss_ = 0;
            lost = AInStop();
            if lost
                error('PMD1208FS:lostData', 'lost data during calibration');
            end
        end
        
        x = x - mean(x);
        
        figure();
        plot(x, y, 'k.', 'MarkerSize', 1);
        mx = min(x);
        xx = max(x);
        
        [xa, i] = sort(abs(x));
        x = x(i);
        y = y(i);
        x(:,2) = 1;
        
        [b, bint, r, rint, stats] = regress(y, x);
        drift = b(1);
        int = bint(1,:);        

        xlabel('time');
        ylabel('snyc error');
        ylim([mx*drift-3*std(r), xx*drift+3*std(r)] + mean(y));

        hold on;
        plot([mx xx], [mx xx]*drift, 'r-', 'LineWidth', 2);
        clockDrift = drift;
        calibrationDate = datenum(date);
    end

        
        
    function readCalibration()
        %read the calibration data from device memory
        bytes = zeros(1, numbytes(CALIBRATION_FORMAT_{:}), 'uint8');
        for i = 0:62:numel(bytes)-1
            len = min(62, numel(bytes)-i);
            bytes(i+1:i+len) = memRead(CALIBRATION_ADDRESS_+i, len);
        end

        [magic, bytes] = ...
            frombytes(bytes, CALIBRATION_FORMAT_{1}, uint8([]));
        
        if (magic ~= CALIBRATION_MAGIC_NUMBER_)
            warning('PMD1208FS:noCalibrationFound', 'No stored calibration was found on this device.');
            return;
        end
        
        [calibrationDate, clockDrift, offsetAdj, gainAdj] = ...
            frombytes(bytes, CALIBRATION_FORMAT_{2:end});
    end




    function memWrite(address, data)
        assertNotOpen_();
        
        if numel(data)~=length(data)
            error('PMD1108FS:illegalArgument','"data" must be a vector.');
        end
        if length(data)>59
            error('PMD1108FS:illegalArgument','"data" vector is too long.');
        end
        if isempty(data)
            error('PMD1108FS:illegalArgument','"data" vector is empty.');
        end
        if any(~ismember(data,0:255))
            error('PMD1108FS:illegalArgument','"data" values must be in the 8-bit range 0 to 255.');
        end
        if (address < 256) || ((address+length(data)) > 1024)
            error('PMD1108FS:illegalArgument','Address out of range.');
        end
        report=zeros(1,4+length(data));
        report(1)=49;
        report(2)=bitand(address,255);
        report(3)=bitshift(address,-8);
        report(4)=length(data);
        report(5:end)=data;
        PsychHIDCheckError_('SetReport',device,2,49,uint8(report)); % MemWrite
    end


    function data = memRead(address, bytes)
        assertNotOpen_();
        
        if ~ismember(bytes,1:63)
            error('Can''t read more than 62 bytes.');
        end
        if ~ismember(bytes,1:63)
            error('Can''t read more than 62 bytes.');
        end
        if (address < 0) || ((address+bytes) > 1024)
            error('PMD1108FS:illegalArgument','Address out of range.');
        end
        
        PsychHIDCheckError_('ReceiveReports',device);
        PsychHIDCheckError_('ReceiveReportsStop',device);
        reports=PsychHIDCheckError_('GiveMeReports',device);

        report=zeros(1,4);
        report(1)=48;
        report(2)=bitand(address,255);
        report(3)=bitshift(address,-8);
        report(4)=0; % unused
        report(5)=bytes;
        PsychHIDCheckError_('SetReport',device,2,48,uint8(report)); % MemRead
        WaitSecs(0.05);
        data=PsychHIDCheckError_('GetReport',device,1,48,bytes+1); % MemRead
        data(1) = [];
        PsychHIDCheckError_('ReceiveReportsStop',device);
    end




    function assertNotOpen_()
        if open
            error('PMD1208FS:illegalOperation', 'Can''t perform operation while device is open');
        end
    end




    function varargout = PsychHIDCheckError_(varargin)
        try
            [varargout{1:nargout}, err] = PsychHID(varargin{:});
            if err.n
                error('PMD1208FS:PsychHIDError','%s error 0x%s. %s: %s\n', varargin{1}, hexstr(err.n),err.name,err.description);
            end
        catch
            rethrow(lasterror);
        end
    end


end