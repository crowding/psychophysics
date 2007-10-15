function this = LabJackUE9(varargin)
%An object that interfaces to the LabJack UE9 over TCP.
%hey here's the command to see what's goping on behind the scenes!
%sudo tcpdump -i en1 -X port 52360 or port 52361

host = 'labjack'; %Address of the device.
portA = 52360;
portB = 52361;
open = 0; %Are we presently open?
readTimeout = 0.2;
writeTimeout = 0.2;

LE_ = struct('littleendian', 1);

%calibration params (%TODO: load these at bootup.
calibration.ADCSlopeOffsetUnipolar = ...
    [  7.7503E-05   3.8736E-05  1.9353E-05  9.6764E-06 ...
    ; -1.2000E-2   -1.2000E-2  -1.2000E-2  -1.200E-02 ...
    ];

calibration.ADCSlopeOffsetBipolar = [1.5629E-04; -5.1760E00];

calibration.DACSlopeOffset = ...
    [ 8.4259E02 8.4259E02 ...
    ; 0.0000E00 0.0000E00 ...
    ];

a_ = []; %connection port A handle.
b_ = []; %connection port B handle.

this = autoobject(varargin{:});


    function setOpen(o)
        if (o ~= open)
            error('LabJackUE9:ReadOnlyProperty', 'use the initializer to open the device.');
        end
    end

    function setReadTimeout(t)
        assertNotOpen();
        readTimeout = t;
    end

    function setWriteTimeout(t)
        assertNotOpen();
        readTimeout = t;
    end

    function setHost(o)
        assertNotOpen_();
        host = o;
    end

    function setPortA(o)
        assertNotOpen_();
        portA = o;
    end

    function setPortB(o)
        assertNotOpen_();
        portB = o;
    end

    %------ COMMANDS ------

    %--- Reset command ---
    
    function reset(hard)
        if nargin > 0 && hard
            sendPacket(COMMAND_RESET_, 1);
            [commandNo, data] = readPacket();
        else
            sendPacket(COMMAND_RESET_, 0);
            [commandNo, data] = readPacket();
        end
        
        if ~isequal(commandNo, COMMAND_RESET_)
            error('LabJackUE9:WrongCommandNumberInResponse', 'incorrect command number in response');
        end
        if ~isequal(data, [0 0])
            error('LabJackUE9:errorReturned', 'error %d (%s) returned from Labjack', data(1), errorCodeToString_(data(1)));
        end
    end

    %------ SingleIO commands ------
    
    SINGLEIO_COMMAND_ = 4;
    

    
    SINGLEIO_ADC_OUT_FORMAT_ = struct...
        ( 'iotype', uint8(0) ...
        , 'channel', uint8(0) ...
        , 'bipGain', uint8(0) ...
        , 'resolution', uint8(0) ...
        , 'settlingTime', uint8(0) ...
        , 'reserved', uint8(0) ...
        );
    
    SINGLEIO_ADC_IN_FORMAT_ = struct...
        ( 'iotype',         uint8(0) ...
        , 'channel',        uint8(0) ...
        , 'AIN',            true(24, 1) ...
        , 'reserved',       uint8(0) ...
        );

    SINGLEIO_DAC_FORMAT_ = struct...
        ( 'iotype',         uint8(0) ...
        , 'channel',        uint8(0) ...
        , 'DAC',       	    uint16(0) ... %TODO: fix endianness in to/frombytes
        , 'reserved',       uint8([0 0]) ...
        );
    
    SINGLEIO_IOTYPE_ = struct ...
        ( 'digitalBitRead',     0 ...
        , 'digitalBitWrite',    1 ...
        , 'digitalPortRead',    2 ...
        , 'digitalPortWrite',   3 ...
        , 'analogIn',           4 ...
        , 'analogOut',          5 ...
        );
    
    SINGLEIO_CHANNEL_ = struct ...
        ( 'FIO', 0 ...
        , 'EIO', 1 ...
        , 'CIO', 2 ...
        , 'MIO', 3 ...
        );
    
    SINGLEIO_DIR_ = struct ...
        ('in',  0 ...
        ,'out', 1 ...
        );

    SINGLEIO_DIGITAL_COMMAND_ = struct...
        ( 'commandNo', 4 ...
        , 'format', struct...
            ( 'iotype',     uint8(0) ...
            , 'channel',    uint8(0) ...
            , 'dir',        false(1,8) ...
            , 'state',      false(1,8) ...
            , 'reserved',   uint8([0 0]) ...
            )...
        , 'response', struct...
            ( 'iotype',     uint8(0) ...
            , 'channel',    uint8(0) ...
            , 'dir',        false(1,8) ...
            , 'state',      false(1,8) ...
            , 'reserved',   uint8([0 0]) ...
            )...
        );
    
    
    function r = bitIn(channel)
        %function r = bitIn(channel)
        %Reads the state of the single digital IO channel specified. 
        %
        %>> a = LabJackUE9; require(a.init(), @()a.bitIn(0))
        %ans = 
        %    channel: 0
        %        dir: 1
        %      state: 1
        assertOpen_();
        
        s = SINGLEIO_DIGITAL_COMMAND_.format;
        
        s.iotype = SINGLEIO_IOTYPE_.digitalBitRead;
        s.channel = channel;
        
        r = roundtrip(SINGLEIO_DIGITAL_COMMAND_, s);
        r.dir = r.dir(1);
        r.state = r.state(1);
        r = rmfield(r, {'iotype', 'reserved'});
    end


    function r = bitOut(channel, dir, state)
        %function r = bitOut(channel, dir, state)
        %Sets the state of a single digital IO line. 'dir' is one for
        %output.
        %
        %>> a = LabJackUE9; require(a.init(), @()a.bitOut(0, 1, 0))
        %ans =
        %    channel: 0
        %        dir: 1
        %      state: 0
        assertOpen_();
        
        s = SINGLEIO_DIGITAL_COMMAND_.format;
        
        s.iotype = SINGLEIO_IOTYPE_.digitalBitWrite;
        s.channel = channel;
        s.dir(end) = dir;
        s.state(end) = state;
        
        r = roundtrip(SINGLEIO_DIGITAL_COMMAND_, s);
        r.dir = r.dir(1);
        r.state = r.state(1);
        r = rmfield(r, {'iotype', 'reserved'});
    end


    function r = portIn(channel)
        %function r = portIn(channel)
        %Reads the state of the digital IO port specified. 
        %   Ports are 0: FIO, 1: EIO, 2, CIO, 3, MIO.
        %
        %>> a = LabJackUE9; require(a.init(), @()a.portIn(0))
        %ans =
        %    channel: 0
        %        dir: [0 0 0 0 0 0 0 1]
        %      state: [1 1 1 1 1 1 1 0]
        assertOpen_();
        
        s = SINGLEIO_DIGITAL_FORMAT_;
        s.iotype = SINGLEIO_IOTYPE_.digitalPortRead;
        s.channel = channel;
        
        [command, r] = sendPacket(SINGLEIO_COMMAND_, toBytes(SINGLEIO_DIGITAL_FORMAT_, s, LE_), 1);
        r = frombytes(r, SINGLEIO_DIGITAL_FORMAT_, LE_);
        r = rmfield(r, {'iotype', 'reserved'});
    end


    function r = portOut(channel, dir, state)
        %function r = portIn(channel)
        %Sets the state of the digital IO port specified. 
        %   Ports are 0: FIO, 1: EIO, 2, CIO, 3, MIO.
        %
        %'dir' and 'state' can be logical arrays or numbers which will be
        %converted to binary.
        %
        %>> a = LabJackUE9; require(a.init(), @()a.portOut(0, [1 1 1 1 1 1 1 1], 42))
        %ans =
        %    channel: 0
        %        dir: [0 0 0 0 0 0 0 1]
        %      state: [1 1 1 1 1 1 1 0]
        assertOpen_();
        
        s = SINGLEIO_ADC_OUT_FORMAT_;

        s.iotype = SINGLEIO_IOTYPE_.digitalPortWrite;
        s.channel = channel;
        s.dir = dir;
        s.state = state;
        
        [command, r] = sendPacket(SINGLEIO_COMMAND_, toBytes(SINGLEIO_ADC_OUT_FORMAT_, s, LE_), 1);
        
        r = frombytes(r, SINGLEIO_ADC_IN_FORMAT_, LE_);
        r = rmfield(r, {'iotype', 'reserved'});
    end



    function r = analogIn(channel, gain, resolution, settlingTime)
        %function r = analogIn(channel, gain, resolution, settlingTime)
        %Reads the specified ADC channel.
        %
        %'gain' sets the range:
        %0 : [0,5]v, 1 : [0,2.5]v, 2 : [0,1.25]v, 3 : [0,0.625]v,
        %8 : [-5,5]v. Default 0.
        %
        %'resolution' is the number of bits, 12-17. Default 16.
        %
        %'settlingTime' adds about 5 usec times this value before taking
        %the sample. Default 0.
        %
        % >> a = LabJackUE9; require(a.init(), @()a.analogIn(0, 0, 17))
        % ans =
        %     channel: 0
        %         AIN: 1.0621
        assertOpen_();
        
        if (nargin<2)
            gain = 0;
        end
        if (nargin<3)
            resolution = 16;
        end
        if (nargin<4)
            settlingTime = 0;
        end
        
        s = SINGLEIO_ADC_OUT_FORMAT_;

        s.iotype = SINGLEIO_IOTYPE_.analogIn;
        s.channel = channel;               
        s.bipGain = gain;
        s.resolution = resolution;
        s.settlingTime = settlingTime;
        
        [command, r] = sendPacket(SINGLEIO_COMMAND_, toBytes(SINGLEIO_ADC_OUT_FORMAT_, s, LE_), 1);
        r = frombytes(r, SINGLEIO_ADC_IN_FORMAT_, LE_);
        
        r = rmfield(r, {'iotype', 'reserved'});
    end



    function r = analogOut(channel, voltage)
        %function r = analogOut(channel, gain, resolution, settlingTime)
        %
        %Sets a DAC value. 'channel' the channel number, 'voltage' in the
        %range [0,4.9] or so (will be clipped).
        %
        %Note that the labjack returns no data in its response.
        % 
        % >> a = LabJackUE9; require(a.init(), @()a.analogOut(0, 4.0))
        % ans =
        %     channel: 0
        %        DACL: 0
        %        DACH: 0
        assertOpen_();
        
        s = SINGLEIO_DAC_FORMAT_;

        s.iotype = SINGLEIO_IOTYPE_.analogOut;
        s.channel = channel;
        
        value = [voltage 1] * calibration.DACSlopeOffset(:,channel+1);
        value = max(value, 0);
        value = min(value, 4095);
        
        s.DACL = mod(value, 256);
        s.DACH = floor(value / 256);
        
        [command, r] = sendPacket(SINGLEIO_COMMAND_, toBytes(SINGLEIO_DAC_FORMAT_, s, LE_), 1);
        
        r = frombytes(r, SINGLEIO_DAC_FORMAT_, LE_);
        
        r = rmfield(r, {'iotype', 'reserved'});
    end



    %------ Flash memory commands ------
    READMEM_COMMAND_ = struct...
        ( 'commandNo',  42 ...
        , 'format', struct...
            ( 'reserved', uint8(0)...
            , 'blocknum', uint8(0)...
            ) ...
        , 'response', struct...
            ( 'reserved', uint8(0)...
            , 'blocknum', uint8(0)...
            , 'data', zeros(128, 1, 'uint8')...
            ) ...
        );
    
    function response = readMem(blocknum)
        if blocknum < 0 || blocknum > 7
            error('LabJackUE9:readMem', 'invalid block number')
        end
        
        packet = READMEM_COMMAND_.format;
        packet.blocknum = blocknum;
        
        response = roundtrip(READMEM_COMMAND_, packet);

        if ~isequal(response.blocknum, blocknum)
            error...
                ( 'LabJackUE9:responseMismatch'...
                , 'response blocknum mismatch: expected %d, was %d'...
                , blocknum, response.blocknum);
        end
    end



    WRITEMEM_COMMAND_ = struct...
        ( 'commandNo', 40 ...
        , 'format', struct...
            ( 'blocknum', uint16(0) ...
            , 'data', zeros(128, 1, 'uint8') ...
            )...
        , 'response', struct...
           ( 'errorcode', uint8(0) ...
           , 'reserved', uint8(0) ...
           ) ...
        );
    
    function writeMem(blocknum, data)
        if blocknum < 0 || blocknum > 7
            error('LabJackUE9:writeMem', 'invalid block number')
        end
        
        packet = WRITEMEM_COMMAND_.format;
        packet.blocknum = blocknum;
        packet.data = data;
        
        response = roundtrip(WRITEMEM_COMMAND_, packet);
    end

    %we ahve a wacky 64 bit point data type for calibration...
    Z_ = struct('frac', uint32(0), 'int', int32(0));

    CALIBRATION_FORMAT_ = struct...
        ( 'ADCUnipolar', struct...
            ( 'slope', {Z_, Z_, Z_, Z_} ...
            , 'offset', {Z_, Z_, Z_, Z_} ) ...
        , 'reserved0',                      zeros(64, 1, 'uint8') ...
        , 'ADCBipolar', struct...
            ( 'slope', {Z_} ...
            , 'offset', {Z_} ) ...
        , 'reserved1',                      zeros(112, 1, 'uint8') ...
        , 'DAC', struct...
            ( 'slope', {Z_, Z_} ...
            , 'offset', {Z_, Z_} ) ...
        , 'temp', struct...
            ( 'slope', {Z_} ...
            , 'slopeLow', {Z_} ) ...
        , 'reserved2',                       [Z_ Z_] ...
        , 'CalTemp',                         Z_ ...
        , 'Vref',                            Z_ ...
        , 'reserved3',                       Z_ ...
        , 'HalfVref',                        Z_ ...
        , 'VsSlope',                         Z_ ...
        , 'reserved4',                       Z_ ...
        , 'ADCUnipolarHighRes',  struct...
            ( 'slope', {Z_} ...
            , 'offset', {Z_} ) ...
        , 'reserved5',                      zeros(112, 1, 'uint8') ...
        , 'ADCBipolarHighRes', struct...
            ( 'slope', {Z_} ...
            , 'offset', {Z_} ) ...
        , 'reserved6',                      zeros(112, 1, 'uint8') ...
        );

    function c = loadCalibration()
        for i = 0:4
            block(i+1) = readMem(i);
            block(i+1).data = block(i+1).data(:)';
        end
        
        c = frombytes([block.data], CALIBRATION_FORMAT_, 'littleendian', 1);
        c = rmfield(c, strcat('reserved', ['123456']'));
        calibration = c;
    end

    %------- COMMS ------

    function response = roundtrip(command, data)
        sendPacket(command.commandNo, tobytes(command.format, data, LE_));
        [commandNo, response] = readPacket();
        if ~isequal(commandNo, command.commandNo)
            error('LabJackUE9:mismatchedCommandNumbers', 'response command number %d from command %d', commandNo, command.commandNo);
        end
            
        response = frombytes(response, command.response, LE_);
    end
    
    function initializer = init(varargin)
        
        initializer = currynamedargs(@i, varargin{:});
        function [release, params] = i(params)
            %fix this...
            assertNotOpen_();
            %open the TCP connection
            a_ = pnet('tcpconnect', host, portA); %does port matter?
            if a_ < 0
                error('LabJackUE9:connection', 'Could not connect');
            end
            pnet(a_, 'setreadtimeout', readTimeout);
            pnet(a_, 'setwritetimeout', writeTimeout);
            b_ = pnet('tcpconnect', host, portB); %does port matter?
            if b_ < 0
                error('LabJackUE9:connection', 'Could not connect');
            end
            pnet(b_, 'setreadtimeout', readTimeout);
            pnet(b_, 'setwritetimeout', writeTimeout);
            open = 1;
            flush();
            
            release = @r;
            function r
                open = 0;
                pnet(a_, 'read', 'noblock');
                pnet(b_, 'read', 'noblock');

                pnet(a_, 'close');
                pnet(b_, 'close');
                a_ = [];
            end
        end
        
    end

    function assertOpen_()
        if ~open
            error('LabJackUE9:DeviceNotOpen', 'Device must be opened. Use the initializer (see HELP REQUIRE.)');
        end
    end

    function assertNotOpen_()
        if open
            error('LabJackUE9:DeviceOpen', 'Can''t do that while device is open');
        end
    end
    
    
    function flush()
        %just read (there's no explicit flush in pnet...)
        assertOpen_();
        pnet(a_, 'read', 'noblock');
        pnet(b_, 'read', 'noblock');
    end
    

    function [commandNo, data] = readPacket()
        in = pnet(a_, 'read', 2, 'uint8');
        if numel(in) < 2
            error('LabJackUE9:ReadTimeOut', 'packet read timeout');
        end
        cksum = in(1);
        commandByte = in(2);
        commandNo = bitand(15, bitshift(in(2), -3));
        if commandNo <= 14
            dataLength = bitand(in(2), 3);
        else
            moar = pnet(a_, 'read', 4, 'uint8');
            if numel(moar) < 4
                error('LabJackUE9:ReadTimeOut', 'packet read timeout');
            end
            dataLength = moar(1);
            commandNo = moar(2);
            cksum2l = moar(3);
            cksum2h = moar(4);
            
        end
        data = pnet(a_, 'read', dataLength*2, 'uint8');
        if numel(data) < dataLength*2
            error('LabJackUE9:ReadTimeOut', 'packet read timeout');
        end
        
        %TODO check checksums
    end

    
    function sendPacket(commandNo, data)
        %send a command to the device. Takes data with words, or bytes in
        %packet order. (they must be uint8s in this case)
        assertOpen_();
        
        %make sure everything is in a reasonable format to begin with.
        %matlab annoyance: incredibly stupid datatype precedence
        %(double + int = int, frex.)
        
        commandNo = double(commandNo);
        
        if strcmp(class(data), 'uint8')
            data = double(data);
        else
            data = double(data);
            data = [mod(data(:)', 256); floor(data(:)'/256)]'
            data = data(:)'
        end
    
        cksum2 = sum(data);

        if mod(numel(data), 2)
            error('LabJackUE9:unevenData', 'Must provide an even number of bytes.');
        end

        if commandNo <= 14
            %normal command
            if numel(data) <= 28
                cbyte = 128 + bitand(commandNo,15)*8 + bitand(numel(data)/2,7);
                cksum = sum([cbyte data]);
                cksum = mod(cksum, 256) + floor(cksum/256); %ones complement accumulator
                packet = uint8([cksum, cbyte, data]);
            else
                error('LabJackUE9:TooMuchData', 'Too much data for this command.');
            end
        else
            %extended command
            if numel(data) <= 500
                cbyte = 248;
                nwords = numel(data)/2;
                xcnum = commandNo;
                cksum2l = mod(cksum2, 256);
                cksum2h = floor(cksum2 / 256);
                
                cksum = sum([cbyte, nwords, xcnum, cksum2l, cksum2h]);
                cksum = mod(cksum, 256) + floor(cksum/256); %ones complement accumulator
                
                packet = uint8([cksum, cbyte, nwords, xcnum, cksum2l, cksum2h, data]);
            else
                error('LabJackUE9:TooMuchData', 'Too much data for this command.');
            end
        end
        
        %send the command
        pnet(a_, 'write', packet);
        %count = pnet(a_, 'write', packet);
        %if count < numel(packet)
        %    error('LabJackUE9:WriteTimeOut', 'packet write timeout');
        %end
    end


    COMMAND_RESET_ = 3;
    
    LJE_UNABLE_TO_READ_CALDATA_ = 254;
    LJE_DEVICE_NOT_CALIBRATED_ = 255;
    LJE_NOERROR_ = 0;
    LJE_INVALID_CHANNEL_NUMBER_ = 2;
    LJE_INVALID_RAW_INPUT_PARAMETER_ = 3;
    LJE_UNABLE_TO_START_STREAM_ = 4;
    LJE_UNABLE_TO_STOP_STREAM_ = 5;
    LJE_NOTHING_TO_STREAM_ = 6;
    LJE_UNABLE_TO_CONFIG_STREAM_ = 7;
    LJE_BUFFER_OVERRUN_ = 8;
    LJE_STREAM_NOT_RUNNING_ = 9;
    LJE_INVALID_PARAMETER_ = 10;
    LJE_INVALID_STREAM_FREQUENCY_ = 11;
    LJE_INVALID_AIN_RANGE_ = 12;
    LJE_STREAM_CHECKSUM_ERROR_ = 13;
    LJE_STREAM_COMMAND_ERROR_ = 14;
    LJE_STREAM_ORDER_ERROR_ = 15;
    LJE_AD_PIN_CONFIGURATION_ERROR_ = 16;
    LJE_REQUEST_NOT_PROCESSED_ = 17;
    LJE_SCRATCH_ERROR_ = 19;
    LJE_DATA_BUFFER_OVERFLOW_ = 20;
    LJE_ADC0_BUFFER_OVERFLOW_ = 21;
    LJE_FUNCTION_INVALID_ = 22;
    LJE_SWDT_TIME_INVALID_ = 23;
    LJE_FLASH_ERROR_ = 24;
    LJE_STREAM_IS_ACTIVE_ = 25;
    LJE_STREAM_TABLE_INVALID_ = 26;
    LJE_STREAM_CONFIG_INVALID_ = 27;
    LJE_STREAM_BAD_TRIGGER_SOURCE_ = 28;
    LJE_STREAM_INVALID_TRIGGER_ = 30;
    LJE_STREAM_ADC0_BUFFER_OVERFLOW_ = 31;
    LJE_STREAM_SAMPLE_NUM_INVALID_ = 33;
    LJE_STREAM_BIPOLAR_GAIN_INVALID_ = 34;
    LJE_STREAM_SCAN_RATE_INVALID_ = 35;
    
    


    function str = errorCodeToString_(code)
        vars = who('LJE_*');
        vals = cellfun(@eval, vars);
        if any(code == vals)
            str = [vars{code == vals}];
        else
            str = num2str(code);
        end
    end

end