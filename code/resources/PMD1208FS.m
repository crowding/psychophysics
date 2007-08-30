function this = PMD1208FS(varargin)
    %Object that interfaces to the PMD1080FS. As of now it only supports
    %executing regularly sampled AInScan operations. 
    
    device = DaqDeviceIndex();
    options = struct ...
        ( 'count', Inf ...
        , 'channel', [0] ...
        , 'range', [0] ...
        , 'f', 1000 ...
        , 'immediate', 0 ...
        , 'trigger', 0 ...
        , 'secs', 0 ...
        , 'print', 0 ...
        );

    open = 0;
    AInScanRunning = 0;

    %how many samples to keep in the backlog before dropping them.
    maxBacklog = 500;
    maxOutOfSync = 0.01;
    
    vmax_=[20,10,5,4,2.5,2,1.25,1];
    dinc_ = [];

    this = autoobject(varargin{:});

    
    function [release, params] = init(params)
        if open
            error('PMD1208FS:illegalOperation', 'Tried to initialize but was already open');
        end
        
        if isempty(device)
            error('PMD1208FS:noDevice', 'No device specified');
        end
            
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
        devices=PsychHID('Devices');
        for dinc_=[-1 1]
            if device+dinc_>=1 && device+dinc_<=length(devices) && (devices(device+dinc_).outputs==65 || devices(device+dinc_).outputs==1)
                break
            else
                dinc_=[];
            end
        end

        AInStop_();
        AOutStop_();

        if devices(device).outputs<70 || isempty(dinc_) || ~streq(devices(device).serialNumber,devices(device+dinc_).serialNumber)
            error(sprintf('Invalid device, not the original USB-1208FS.'));
        end

        err=DaqALoadQueue(device,options.channel,options.range);
        if err.n
            fprintf('DaqALoadQueue error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
        end
        
        open = 1;
        release = @release_;
        
        function release_()
            AInStop();
            AOutStop();
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
        if any(o.range < 0 | o.range >= length(vmax_))
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



    function [fActual ,prescale, preload] = nearestF(f, channel)
        %computes the nearest available sampling  frequency to the desired
        %one, as well as low-level prescale and preload parameters. pass
        %the channel argument for the nearest frequency under a particular
        %channel sequence.
        
        if nargin < 2
            channel = options.channel;
        end
        
        f = f * numel(channel);
        prescale=ceil(log2(10e6/65535/f)); % Use smallest integer timer_prescale consistent with pmd.f.
        prescale=max(0,min(8,prescale)); % Restrict to available range.
        preload=round(10e6/2^prescale/f);
        preload=max(1,min(65535,preload)); % Restrict to available range.
        fActual = 10e6/2^prescale/preload / numel(channel);
    end



    %state variables used during an AInScan()
    fActual_ = [];
    tBegin_ = [];
    tFirstPacket_ = [];
    syncadj_ = 0;
    maxsync_ = 0;

    incompleteSamples_ = [];
    incompleteChannels_ = [];
    incompleteData_ = [];
    
    warnedDataLoss_ = 0;
    warnedSyncLoss_ = 0;
    
    wrapping_ = 0;
    serialOffset_ = 0;
    
    function AInScanBegin(tBegin)
        if (nargin >= 1)
            tBegin_ = tBegin;
        else
            tBegin_ = 0;
        end
        
        tFirstPacket_ = [];
        syncadj_ = 0;
        maxsync_ = 0;

        incompleteSamples_ = [];
        incompleteChannels_ = [];
        incompleteData_ = [];

        warnedDataLoss_ = 0;
        warnedSyncLoss_ = 0;
        
        wrapping_ = 0;
        serialOffset_ = 0;

        if ~open
            error('PMD1208FS:notInitialized', 'need to initialize with require(device.init(), @code)');
        end
        
        %build the report to begin scan.s. The channel queue is already
        %loaded by open();
        c = numel(options.channel);
        [fActual_, timer_prescale, timer_preload] = nearestF(options.f);
        
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
        err=PsychHID('SetReport',device,2,17,report); % AInScan
        if err.n
            fprintf('AInScan SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
        end
        AInScanRunning = 1;
    end




    function [data, t] = AInScanSample()
        if ~AInScanRunning
            error('PMD1208FS:illegalOperation', 'need to start scan before sampling');
        end

        %return samples and nominal time since start
        reports = [];
        new = [0];
        %if options.secs is zero, loop until we have everything
        tic = GetSecs;
        while(~isempty(new))
            new = [];
            for d = (1:3)*dinc_
                err = PsychHID('ReceiveReports', device+d, options); %options.print
                if err.n
                    fprintf('AInScan device %d, ReceiveReports error 0x%s. %s: %s\n',device+d,hexstr(err.n),err.name,err.description);
                end
                [r, err] = PsychHID('GiveMeReports', device+d);
                if err.n
                    fprintf('AInScan device %d, GiveMeReports error 0x%s. %s: %s\n',device+d,hexstr(err.n),err.name,err.description);
                end
                new = [new r];
            end
            reports = [reports new];
            if (options.secs)
                break;
            end
        end
        toc = getSecs;
        
        if isempty(tFirstPacket_)
            tFirstPacket_ = min([reports.time]);
        end
        
        if ~isempty(reports)
            c = numel(options.channel);

            %TODO: Handle count/retrigger options (i.e. don't report
            %past-the-count data as being samples, and find out whether
            %retriggering starts a new packet -- at present it looks as if
            %my PMD-1208FS doesn't support the retrigger option so this ia
            %moot point.
            
            if (options.immediate)
                bytes = 2;
                samplesPer = 1;
            else
                bytes = 62;
                samplesPer = 31;
            end

            data = zeros(bytes, numel(reports));
            serials = zeros(1, numel(reports));
            for i = 1:numel(reports)
                r = reports(i).report;
                data( :, i ) = r(1:bytes);
                serials(i) = double(r(63))+256*double(r(64));
            end

            %combine as SIGNED shorts, scaling to the range [-1..1)
            data = (data(1:2:end, :) + data(2:2:end, :)*256);
            data = (data-(65536*(data>=32768))) ./ 32768;

            %Deal with wraparound of the packet serial number.
            if (max(serials) >= 65535-ceil(maxBacklog/samplesPer) && min(serials) <= ceil(maxBacklog/samplesPer))
                serials(serials<=32768) = serials(serials<=32768) + 65536;
                wrapping_ = 1;
            else
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
                if (~warnedDataLoss_)
                    warning('PMD1208FS:lostData', 'Packet serial numbers indicate data loss');
                    warnedDataLoss_ = 1;
                end
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

            
            
            samples = firstSample:lastSample;
            times = samples / fActual_ + tBegin_ + syncadj_;
            
            %Inspect for the discrepancy of time packets received versus
            %time indicated.
            sync = max([reports.time]) - tFirstPacket_ - max(times) + tBegin_ + toc - tic;
            if abs(sync) > maxOutOfSync
                if ~warnedSyncLoss_
                    warning('PMD1208FS:outOfSync', 'Timing of packet receipt is out of sync with sample count. Adjusting, but I need to skew the clock...');
                    warnedSyncLoss_ = 1;
                end
                
                syncadj_ = syncadj_ + sync;
                times = times + sync;
            end
            if abs(sync) > abs(maxsync_)
                maxsync_ = sync;
            end

            %these samples are good, forward them on
            good = all(~isnan(assembled), 1);
            data = assembled(:,good);
            [t, i] = sort(times(good));
            data = data(:,i);
            
            %deal with the incomplete samples (hold them over)
            assembled(:,good) = [];
            samples(:, good) = [];
            
            incomplete = ~isnan(assembled);
            [channelix, sampleix] = find(incomplete);

            incompleteSamples_ = samples(sampleix);
            incompleteChannels_ = channelix - 1;
            incompleteData_ = assembled(incomplete);

            %FINALLY, apply the gain adjustment
            gains = vmax_(options.range(:))';
            data = data .* gains(:, ones(1, size(data, 2)));
        else
            %keeping zero dimension arrays dimensions consistent is
            %nice
            data = zeros(numel(options.channel), 0);
            t = zeros(1, 0);
        end
    end


    function r = vmax()
        %returns the range for each channel.
        r = vmax_(options.range(:) + 1)';
    end


    function AInStop()
        if ~open
            error('PMD1208FS:notInitialized', 'need to initialize with require(device.init(), @code)');
        else
            AInStop_();
        end
        if maxsync_
            fprintf('worst sync: %f\n', maxsync_)
            maxsync_ = 0;
        end
    end




    function AInStop_()
        %private function, doesn't care
        err=PsychHID('SetReport',device,2,18,uint8(0));
        if err.n
            fprintf('AInStop SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
        end

        flush_();

        for d=(1:3)*dinc_
            err=PsychHID('ReceiveReportsStop',device+d);
            if err.n
                fprintf('AInStop device %d, ReceiveReportsStop error 0x%s. %s: %s\n',device+d,hexstr(err.n),err.name,err.description);
            end
        end
    end


    function flush_()
        % Flush any stale reports.
        for d=(1:3)*dinc_ % Interfaces 1,2,3
            err=PsychHID('ReceiveReports',device+d);
            if err.n
                fprintf('flush_ device %d, ReceiveReports error 0x%s. %s: %s\n',device+d,hexstr(err.n),err.name,err.description);
            end
        end
        
        for d=(1:3)*dinc_ % Interfaces 1,2,3
            [reports,err]=PsychHID('GiveMeReports',device+d);
            if ~isempty(reports) && options.print
                fprintf('Flushing %d stale reports from device %d.\n',length(reports),device+d);
            end
        end
    end



    function AOutStop
        if ~open
            error('PMD1208FS:notInitialized', 'need to initialize with require(device.init(), @code)');
        else
            AOutStop_();
        end
    end



    function AOutStop_()
        %Private version, does not check if device is open.
        err=PsychHID('SetReport',device,2,22,uint8(0));
        if err.n
            fprintf('AOutStop SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
        end
    end



    function reset()
        if open
            error('PMD1208FS:illegalOperation', 'can''t reset while open');
        end

        fprintf('Resetting USB-1208FS.\n');
        clear PsychHID; % flush current enumeration  (list of devices)
        WaitSecs(1); %don't know why this is necessary
        daq=DaqDeviceIndex();
        if isempty(daq)
            error('Sorry, couldn''t find a USB-1208FS.');
        end
        if ~any(ismember(device,daq))
            warning('PMD1108FS:deviceIndexChanged', 'The device at index %d was not found. Changing to %d', device, daq(1));
            device=daq(1);
        end

        % Reset. Ask the USB-1208FS to reset its USB interface.
        err=PsychHID('SetReport',device,2,65,uint8(65)); % Reset
        if err.n
            fprintf('reset SetReport error 0x%s. %s: %s\n',hexstr(err.n),err.name,err.description);
        end
        
        % CAUTION: Immediately after RESET, all commands fail, returning error
        % messages saying the command is unsupported (0xE00002C7) or the device is
        % not responding (0xE00002ED) or not attached (0xE00002D9). To restore
        % communication we must flush the current enumeration and re-enumerate the
        % HID-compliant devices.
        clear PsychHID; % flush current enumeration  (list of devices)
        WaitSecs(1); %don't know why this is necessary, again
        PsychHID('Devices');
    end
end