function this = LabJackUE9(varargin)
%persistent init__;
%An object that interfaces to the LabJack UE9 over TCP.
%hey here's the command to see what's goping on behind the scenes!
%sudo tcpdump -i en1 -X port 52360 or port 52361

host = '100.1.1.3'; %Address of the device.
portA = 52360;
portB = 52361;
open = 0; %Are we presently open?
readTimeout = 0.2;
writeTimeout = 0.2;
discoveryTimeout = 0.2;
debug = 1;

LE_ = struct('littleendian', 1);

%Calibration params. These are copied from my personal labjack. Yalues from
%your labjack will be will be loaded at initialization.
calibration.ADCUnipolar = cell(1,4);
calibration.ADCUnipolar{1,1}.slope = 7.7561940997839e-05;
calibration.ADCUnipolar{1,1}.offset = -0.0116342853289098;
calibration.ADCUnipolar{1,2}.slope = 3.87721229344606e-05;
calibration.ADCUnipolar{1,2}.offset = -0.0120969316922128;
calibration.ADCUnipolar{1,3}.slope = 1.93545129150152e-05;
calibration.ADCUnipolar{1,3}.offset = -0.0123288538306952;
calibration.ADCUnipolar{1,4}.slope = 9.64500941336155e-06;
calibration.ADCUnipolar{1,4}.offset = -0.0123841688036919;
calibration.ADCUnipolar = cell2mat(calibration.ADCUnipolar);
calibration.ADCBipolar.slope = 0.000156391179189086;
calibration.ADCBipolar.offset = -5.17294792411849;
calibration.DAC = cell(1,2);
calibration.DAC{1,1}.slope = 842.220494680107;
calibration.DAC{1,1}.offset = -19.5067721442319;
calibration.DAC{1,2}.slope = 840.558117963374;
calibration.DAC{1,2}.offset = -27.1995932771824;
calibration.DAC = cell2mat(calibration.DAC);
calibration.temp.slope = 0.0125841302797198;
calibration.temp.offset = 0;
calibration.tempLow.slope = 0.012831287458539;
calibration.tempLow.offset = 0;
calibration.CalTemp = 299.879827279132;
calibration.Vref = 2.42993684369139;
calibration.HalfVref = 1.21196511248127;
calibration.Vs.slope = 9.26947686821222e-05;
calibration.Vs.offset = 0;
calibration.ADCUnipolarHighRes.slope = -2.3283064365387e-10;
calibration.ADCUnipolarHighRes.offset = -2.3283064365387e-10;
calibration.ADCBipolarHighRes.slope = -2.3283064365387e-10;
calibration.ADCBipolarHighRes.offset = -2.3283064365387e-10;

a_ = []; %TCP connection port handle
b_ = [];

persistent init__;
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

    function IP = getIPAddress()
        assertOpen_();
        IP = pnet(a_, 'gethost');
    end

    %------ COMMANDS ------
    
%% CommConfig
    
    COMMCONFIG_COMMAND_ = struct...
        ( 'remote', 0 ...
        , 'extended', 1 ...
        , 'commandNo', 1 ...
        , 'format', struct...
            ( 'writeMask', struct... %mask for writing...
                ( 'LocalID',        false ...
                , 'PowerLevel',     false ...
                , 'IPAddress',      false ...
                , 'Gateway',        false ...
                , 'Subnet',         false ...
                , 'PortA',          false ...
                , 'PortB',          false ...
                , 'DHCPEnabled',    false ...
                ) ...
            , 'reserved0',      uint8(0)...
            , 'LocalID',            uint8(1) ...
            , 'PowerLevel',         uint8(0) ...
            , 'IPAddress',          uint8([192 168 1 209]) ... %actual format is little endian (see writecommconfig)
            , 'Gateway',            uint8([192 168 1 1])... %ditto
            , 'Subnet',             uint8([255 255 255 0])... %ditto
            , 'PortA',              uint16(52360)...
            , 'PortB',              uint16(52361) ...
            , 'DHCPEnabled',        false...
            , 'reserved1',          false(1, 7)...
            , 'ProductID',          uint8(0)...
            , 'MACAddress',         zeros(1, 6, 'uint8')...
            , 'HWVersion', struct...
                ( 'int',            uint8(0)...
                , 'frac',           uint8(0)...
                )...
            , 'CommFWVersion', struct...
                ( 'int',            uint8(0)...
                , 'frac',           uint8(0)...
                )...
            )...
        , 'response', []...
        );
    COMMCONFIG_COMMAND_.response = COMMCONFIG_COMMAND_.format;
                
    function response = readCommConfig()
        data = COMMCONFIG_COMMAND_.format;
        response = roundtrip(COMMCONFIG_COMMAND_, data);
        response = flipaddress_(response); %we usually see IP/MAC addresses as big endian
        response = rmfield(response, {'reserved0', 'reserved1'});
    end

    function response = writeCommConfig(varargin)
        %Sets the comm config parameters. Takes structs or names arguments.
        %Example use:
        %
        %>> a = LabJackUE9();
        %>> require(a.init(), @()a.writeCommConfig('LocalID', 2))
        params = namedargs(varargin{:});
        data = COMMCONFIG_COMMAND_.format;
        for i = fieldnames(params)'
            if ~isfield(data.writeMask, i{:})
                error('LabJackUE9:unknownCommOption', 'unknown or read-only option %s', i{:})
            end
            data.writeMask.(i{:}) = true;
            data.(i{:}) = params.(i{:});
        end
        
        data = flipaddress_(data);
        
        response = roundtrip(COMMCONFIG_COMMAND_, data);
        response = rmfield(response, {'reserved0', 'reserved1'});
    end

%% DiscoveryUDP

    UDP_DISCOVERY_PORT_ = 52362;

    function discovery = discover(broadcast)
        %function discovery = discover(broadcast)
        %Discovers the Labjack on the local subnet via broadcasting UDP
        %packets. returns an array of the communications configurations al
        %all labjacks which responded. If no hostname of port was set
        %previously, the first labjack whish responded is used for the host
        %and port of future connections.
        %
        %Accepts an optional 'broadcast' parameter. This is the address to
        %which a query is sent. Default is 255.255.255.255, but this may
        %not get through certain networks (and the packet will only go out
        %on one interface if you have multiple interfaces.)
        %
        %Note this won't work unless you modify pnet.c to use set the
        %broadcast option on UDP sockets and use inet_atoi when looking
        %up hostnames.
        %
        %TODO: Modify pnet.c to emumerate the interfaces on the machine
        %and send the appropriate broadcast packets to each interface.
        %See this page for code:
        %http://www.doctort.org/adam/nerd-notes/enumerating-network-interfa
        %ces-on-linux.html
        
        discovery = COMMCONFIG_COMMAND_.response([]); %empty structure...
        
        require(currynamedargs(@opensocket_, 'port', 52363), @disco)
        function disco(params)
            pnet(params.socket, 'setreadtimeout', discoveryTimeout);
            pnet(params.socket, 'write', uint8([34 120 0 169 0 0]));
            pnet(params.socket, 'writepacket', broadcast, UDP_DISCOVERY_PORT_);
            
            size = pnet(params.socket, 'readpacket');
            while size
                [commandNo, payload] = readPacket(params.socket);
                discovery(end+1) = frombytes(payload, COMMCONFIG_COMMAND_.response);
                discovery(end) = flipaddress_(discovery(end));
                size = pnet(params.socket, 'readpacket');
            end
        end
        
        if (isempty(host) || isempty(portA) || isempty(portB)) && ~isempty(discovery)
            host = sprintf('%d.%d.%d.%d', discovery(1).IPAddress);
            portA = discovery(1).PortA;
            portB = discovery(1).PortB;
        end
    end

    function commstruct = flipaddress_(commstruct)
        %flip IP addresses used by Labjack around to the more familiar big-endian
        %order, or vice versa.
        commstruct.IPAddress = flipud(commstruct.IPAddress(:))';
        commstruct.Gateway = flipud(commstruct.Gateway(:))';
        commstruct.Subnet = flipud(commstruct.Subnet(:))';
        commstruct.MACAddress = flipud(commstruct.MACAddress(:))';
    end
                
    function [release, params] = opensocket_(params)
        params.socket = pnet('udpsocket', params.port);
        if params.socket < 0
            error('LabJackUE9Test:nosocket', 'could not open socket');
        end
        release = @close;
        function close()
            pnet(params.socket, 'close');
        end
    end

%% ControlConfig

CONTROLCONFIG_COMMAND_ = struct...
    ( 'extended', 1 ...
    , 'commandNo', 8 ...
    , 'format', struct...
        ( 'WritePowerLevel',        false ...
        , 'WriteMask', struct...
            ( 'IO',                 false ...
            , 'DAC',                false ...
            )...
        , 'reserved0',              false(1,5) ...
        , 'PowerLevel',             false ...
        , 'reserved1',              false(1,7) ...
        , 'FIODir',                 false(1,8) ...
        , 'FIOState',               false(1,8) ...
        , 'EIODir',                 false(1,8) ...
        , 'EIOState',               false(1,8) ...
        , 'CIOState',               false(1,4) ... %tobytes respects endianness in bit order
        , 'CIODir',                 false(1,4) ...
        , 'MIOState',               false(1,3) ...
        , 'reserved2',              false ...
        , 'MIODir',                 false(1,3) ...
        , 'IODontLoadDefaults',     false      ...
        , 'DAC0Value',              true(1,12)  ... %12 bits of output
        , 'reserved3',              true(1,3)  ...
        , 'DAC0Enabled',            false ...
        , 'DAC1Value',              true(1,12)  ... %12 bits of output
        , 'reserved4',              true(1,3)  ...
        , 'DAC1Enabled',            false ...
        )...
    , 'response', struct...
        ( 'Errorcode',              uint8(0) ...
        , 'PowerLevel',             false ...
        , 'reserved0',              false(1,7) ...
        , 'ResetSource',            uint8(0) ... %unused?
        , 'ControlFWVersion', struct...
                ( 'int',            uint8(0)...
                , 'frac',           uint8(0)...
                )...
        , 'ControlBLVersion', struct...
                ( 'int',            uint8(0)...
                , 'frac',           uint8(0)...
                )...
        , 'HiRes',                  false ...
        , 'reserved1',              false(1,7) ...
        , 'FIODir',                 false(1,8) ...
        , 'FIOState',               false(1,8) ...
        , 'EIODir',                 false(1,8) ...
        , 'EIOState',               false(1,8) ...
        , 'CIOState',               false(1,4) ... %bits 0-3
        , 'CIODir',                 false(1,4) ...
        , 'MIOState',               false(1,3) ...
        , 'reserved2',              false ...
        , 'MIODir',                 false(1,3) ...
        , 'IOLoadDefaults',         false      ...
        , 'DAC0Value',              true(1,12)  ... %unsigned int value
        , 'reserved3',              false(1,3)  ...
        , 'DAC0Enabled',            false ...
        , 'DAC1Value',              true(1,12)  ...
        , 'reserved4',              false(1,3)  ...
        , 'DAC1Enabled',            false ...
        )...
    );
    
    
    function r = readControlConfig()
        assertOpen_();
        r = roundtrip(CONTROLCONFIG_COMMAND_, CONTROLCONFIG_COMMAND_.format);
        r = rmfield(r, {'reserved0', 'reserved1', 'reserved2', 'reserved3', 'reserved4'});
    end

    function r = writeControlConfig(varargin)
        %function r = writeControlConfig(varargin)
        %Changes the control configiuration. Specify named arguments in two
        %groups
        %
        %IO group: FIODir, FIOState, EIODir, EIOState, CIODir, CIOState
        %   Each are 1x8 boolean. To disable these, set 'IODontLoadDefaults' to
        %   true.
        %
        %DAC group: DAC0Enabled, DAC0Value, DAC1Enabled, DAC1Value
        %   'Enabled' gets boolean, and 'value' gets an integer 12-bit
        %   value (raw hardware units -- calibration conversion not
        %   yet implemented)
        %
        %PowerLevel: Boolean. Sets the current power level. If
        %   'WritePowerLevel' is provided and also 1, writes the power level
        %   to flash.
        %
        %Example usage: Configure FIO to be all inputs at startup
        %
        %>> a.writeControlConfig('IOLoadDefaults', 1, 'FIODir', [0 0 0 0 0 0 0 0]);
        %
        %Example: set to low power mode, and configure so that device
        %always starts in low power mode.
        %
        %>> a.writeControlConfig('PowerLevel', 1, 'WritePowerLevel', 1);
        %
        %When only providing some parameters in a group e.g. DAC or IO, the
        %other parameters will be filled in by reading the settings from
        %the device.
        assertOpen_();
        args = namedargs(varargin{:});
        
        %start with the current settings
        state = readControlConfig();
        packet = CONTROLCONFIG_COMMAND_.format;
        for j = fieldnames(state)'
            if isfield(packet, j{:})
                packet.(j{:}) = state.(j{:});
            end
        end
        
        %apply user arguments and figure the write mask.
        for i = fieldnames(args)'
            if strfind(i{:}, 'IO')
                packet.WriteMask.IO = true;
                packet.(i{:}) = args.(i{:});
            elseif strfind(i{:}, 'DAC')
                %TODO provide
                packet.WriteMask.DAC = true;
                packet.(i{:}) = args.(i{:});
            elseif isfield(packet, i{:})
                packet.(i{:}) = args.(i{:});
            else
                error('LabJackUE9:unknownOption', 'unknown config option %s', i{:});
            end
        end
        r = roundtrip(CONTROLCONFIG_COMMAND_, packet);
        r = rmfield(r, {'reserved0', 'reserved1', 'reserved2', 'reserved3', 'reserved4'});
    end

%% Feedback and FeedbackAlt
% ------Feedback command reads and writes everything!------

FEEDBACK_COMMAND_ = struct...
    ( 'extended', 1 ...
    , 'commandNo', 0 ...
    , 'format', struct...
        ( 'FIOMask',            false(1, 8)...
        , 'FIODir',             false(1, 8)...
        , 'FIOState',           false(1, 8)...
        , 'EIOMask',            false(1, 8)...
        , 'EIODir',             false(1, 8)...
        , 'EIOState',           false(1, 8)...
        , 'CIOMask',            false(1, 4)...
        , 'reserved0',          false(1, 4)...
        , 'CIOState',           false(1, 4)...
        , 'CIODir',             false(1, 4)...
        , 'MIOMask',            false(1, 3)...
        , 'reserved1',          false(1, 5)...
        , 'MIOState',           false(1, 3)...
        , 'reserved2',          false...
        , 'MIODir',             false(1, 3)...
        , 'reserved3',          false...
        , 'DAC0Value',          true(12, 1)...
        , 'reserved4',          false(2, 1)...
        , 'DAC0Update',         false...
        , 'DAC0Enabled',        false...
        , 'DAC1Value',          true(12, 1)...
        , 'reserved5',          false(2, 1)...
        , 'DAC1Update',         false...
        , 'DAC1Enabled',        false...
        , 'AINMask',            false(1, 16)...
        , 'AIN14ChannelNumber', uint8(0)...
        , 'AIN15ChannelNumber', uint8(0)...
        , 'Resolution',         uint8(0)...
        , 'SettlingTime',       uint8(0)...
        , 'AINGain',            true(4, 16)...
        )...
    , 'response', struct...
        ( 'FIODir',             false(1, 8)...
        , 'FIOState',           false(1, 8)...
        , 'EIODir',             false(1, 8)...
        , 'EIOState',           false(1, 8)...
        , 'CIOState',           false(1, 4)...
        , 'CIODir',             false(1, 4)...
        , 'MIOState',           false(1, 3)...
        , 'reserved0',          false(1, 2)...
        , 'MIODir',             false(1, 3)...
        , 'AIN',                uint16(zeros(1, 16))...
        , 'Counter0',           uint16(0)...
        , 'Counter1',           uint16(0)...
        , 'TimerA',             uint16(0)...
        , 'TimerB',             uint16(0)...
        , 'TimerC',             uint16(0)...
        )...
    );
        
        
    function r = feedback(varargin)
        %The feedback command can read or write practically everything.
        %It takes named arguments.
        %
        %For digital IO, set parameters
        %'xIOMask', 'xIODir' and 'xIOState' where x in {F,E,C,M} and the
        %arguments are logical arrays of 8,8,4,3 elements respectively. The
        %mask controls which bits of dir and state are written.
        %
        %For Analog output, set 'DACxUpdate' then 'DACxEnabled' and 'DACxValue.'
        %Alternately you can provide 'DACxVoltage' and it will scale
        %appropriately.
        %
        %For analog input, set 'AINMask' (a 16-element boolean array which
        %defaults to true) and 'AINGain' (a 16-element array defaulting to
        %0). 'Resolution' (16) and 'SettlingTime' (0) are available as
        %well. 16 is the max for Resolution.
        %
        %Set arguments 'AIN14ChannelNumber' and 'AIN15ChannelNumber' to
        %appropriate numbers to read internal channels.
        %
        %The response contains dir and state for digital ports, all AIN
        %measurements in raw format as 'AIN' and in calibrated format as
        %'AINValue', and the values of the timers and counters.
        
        packet = FEEDBACK_COMMAND_.format;
        packet.AINMask(:) = 1; %default to all channels read.
        packet.AINGain = zeros(1, 16);
        
        args = namedargs(varargin{:});
        
        for i = fieldnames(args)'
            switch(i{:})
                case 'DAC0Voltage'
                    packet.DAC0Value = aoutcal_(0, args.DAC0Voltage);
                case 'DAC1Voltage'
                    packet.DAC1Value = aoutcal_(0, args.DAC1Voltage);
                otherwise
                    if isfield(packet, i{:})
                        packet.(i{:}) = args.(i{:});
                    else
                        error('LabJackUE9:unknownOption', 'unknown feedback option %s', i{:});
                    end
            end
        end
                    
        r = roundtrip(FEEDBACK_COMMAND_, packet);
        
        %calibrate the analog reads
        channel = [0:13 packet.AIN14ChannelNumber packet.AIN15ChannelNumber];
        r.AINValue = ainCal_(r.AIN, channel, packet.AINGain, packet.Resolution);
        
        r = rmfield(r, {'reserved0'});
    end

FEEDBACKALT_COMMAND_ = struct...
    ( 'extended', 1 ...
    , 'commandNo', 1 ...
    , 'format', struct...
        ( 'FIOMask',            false(1, 8)...
        , 'FIODir',             false(1, 8)...
        , 'FIOState',           false(1, 8)...
        , 'EIOMask',            false(1, 8)...
        , 'EIODir',             false(1, 8)...
        , 'EIOState',           false(1, 8)...
        , 'CIOMask',            false(1, 4)...
        , 'reserved0',          false(1, 4)...
        , 'CIOState',           false(1, 4)...
        , 'CIODir',             false(1, 4)...
        , 'MIOMask',            false(1, 3)...
        , 'reserved1',          false(1, 5)...
        , 'MIOState',           false(1, 3)...
        , 'reserved2',          false...
        , 'MIODir',             false(1, 3)...
        , 'reserved3',          false...
        , 'DAC0Value',          true(12, 1)...
        , 'reserved4',          false(2, 1)...
        , 'DAC0Update',         false...
        , 'DAC0Enabled',        false...
        , 'DAC1Value',          true(12, 1)...
        , 'reserved5',          false(2, 1)...
        , 'DAC1Update',         false...
        , 'DAC1Enabled',        false...
        , 'AINMask',            false(1, 16)...
        , 'AIN14ChannelNumber',   uint8(13)...
        , 'AIN15ChannelNumber',   uint8(13)...
        , 'Resolution',         uint8(0)...
        , 'SettlingTime',       uint8(0)...
        , 'AINGain',            true(4, 16)...
        , 'AINChannelNumber',   uint8(0:13)...
        )...
    , 'response', struct...
        ( 'FIODir',             false(1, 8)...
        , 'FIOState',           false(1, 8)...
        , 'EIODir',             false(1, 8)...
        , 'EIOState',           false(1, 8)...
        , 'CIOState',           false(1, 4)...
        , 'CIODir',             false(1, 4)...
        , 'MIOState',           false(1, 3)...
        , 'reserved0',          false(1, 2)...
        , 'MIODir',             false(1, 3)...
        , 'AIN',                uint16(zeros(1, 16))...
        )...
    );

    function r = feedbackAlt(varargin)
        %Like 'Feedback' except that there is a 'AINChannelNumber' parameter that
        %takes a 16-element array; it allows you to redirect all 16
        %channel samplings.
        
        packet = FEEDBACKALT_COMMAND_.format;
        packet.AINMask(:) = 1; %default to all channels read.
        packet.AINGain = zeros(1, 16);
        
        args = namedargs(varargin{:});
        
        for i = fieldnames(args)'
            switch(i{:})
                case 'DAC0Voltage'
                    packet.DAC0Value = aoutcal_(0, args.DAC0Voltage);
                case 'DAC1Voltage'
                    packet.DAC1Value = aoutcal_(0, args.DAC1Voltage);
                case 'AINChannelNumber'
                    %it isn't well ordered in the spec...
                    packet.AINChannelNumber = args.AINChannelNumber(1:14);
                    packet.AIN14ChannelNumber = args.AINChannelNumber(15);
                    packet.AIN15ChannelNumber = args.AINChannelNumber(16);
                otherwise
                    if isfield(packet, i{:})
                        packet.(i{:}) = args.(i{:});
                    else
                        error('LabJackUE9:unknownOption', 'unknown feedback option %s', i{:});
                    end
            end
        end

        r = roundtrip(FEEDBACKALT_COMMAND_, packet);
        
        %calibrate the analog reads
        channel = [packet.AINChannelNumber(:)' packet.AIN14ChannelNumber packet.AIN15ChannelNumber];
        r.AINValue = ainCal_(r.AIN(:), channel(:), packet.AINGain(:), packet.Resolution);
        
        r = rmfield(r, {'reserved0'});
    end

%% SingleIO
    %------ SingleIO commands ------
    
    SINGLEIO_COMMAND_ = 4;
    
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

    SINGLEIO_BIT_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_ ...
        , 'format', struct...
            ( 'iotype',     uint8(0) ...
            , 'channel',    uint8(0) ...
            , 'dir',        false ...       %false for input, true for output
            , 'reserved0',  false(1, 7) ...
            , 'state',      false ...
            , 'reserved1',  false(1, 23) ...
            )...
        , 'response', struct...
            ( 'iotype',     uint8(0) ...
            , 'channel',    uint8(0) ...
            , 'dir',        false ...
            , 'reserved0',  false(1, 7) ...
            , 'state',      false ...
            , 'reserved1',  false(1, 23) ...
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
        
        s = SINGLEIO_BIT_COMMAND_.format;
        
        s.iotype = SINGLEIO_IOTYPE_.digitalBitRead;
        s.channel = channel;
        
        r = roundtrip(SINGLEIO_BIT_COMMAND_, s);
        r = rmfield(r, {'iotype', 'reserved0', 'reserved1'});
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
        
        s = SINGLEIO_BIT_COMMAND_.format;
        
        s.iotype = SINGLEIO_IOTYPE_.digitalBitWrite;
        s.channel = channel;
        s.dir = dir;
        s.state = state;
        
        r = roundtrip(SINGLEIO_BIT_COMMAND_, s);
        r = rmfield(r, {'iotype', 'reserved0', 'reserved1'});
    end

    SINGLEIO_ANALOGIN_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_...
        , 'format', struct...
            ( 'iotype',         uint8(SINGLEIO_IOTYPE_.analogIn) ...
            , 'channel',        uint8(0) ...
            , 'bipGain',        uint8(0) ...
            , 'resolution',     uint8(16) ...
            , 'settlingTime',   uint8(0) ...
            , 'reserved',       uint8(0) ...
            ) ...
        , 'response',  struct...
            ( 'iotype',         uint8(0) ...
            , 'channel',        uint8(0) ...
            , 'AIN',            true(24, 1) ...
            , 'reserved',       uint8(0) ...
            )...
        );

    function r = analogIn(channel, gain, resolution, settlingTime)
        %function r = analogIn(channel, gain, resolution, settlingTime)
        %Reads the specified ADC channel, adn returns the read
        %
        %Channel numbers
        %0-13 are the built-in inputs. 
        %
        %14, 128 are Vref;
        %15, 136 are GND;
        %132, 140 are Vsupply;
        %133, 141 is the ambient temperature in Kelvin
        %
        %Channels 14-127 activate the multiplexer pins for extended
        %channels. The lower 3 bits of the channel number determine the
        %multiplexer output and the high 4 bits 
        %
        %'gain' sets the range of the reading:
        %0 : [0,5]v, 1 : [0,2.5]v, 2 : [0,1.25]v, 3 : [0,0.625]v,
        %8 : [-5,5]v. Default 0.
        %
        %'resolution' is the number of bits, effective range 12-17. Default
        %16. 18+ is for use with UE9-Pro devices (can only use gains 0 and
        %8)
        %
        %'settlingTime' adds about 5 usec per count this value before taking
        %the sample. Default 0.
        %
        % The raw 24-bit ADC (upper 16 are used) ADC value is returned
        % in the field 'AIN', and an additional field 'value' converts to
        % physical units according to the labJack's calibration.
        %
        % >> a = LabJackUE9; require(a.init(), @()a.analogIn(0, 0, 17))
        % ans =
        %     channel: 0
        %         AIN: ...
        %       value: 1.0621
        assertOpen_();
        
        s = SINGLEIO_ANALOGIN_COMMAND_.format;
        s.channel = channel;
        if (nargin>=2)
            s.bipGain = gain;
        end
        if (nargin>=3)
            s.resolution = resolution;
        end
        if (nargin>=4)
            s.settlingTime = settlingTime;
        end
        
        r = roundtrip(SINGLEIO_ANALOGIN_COMMAND_, s);
        r.value = ainCal_(r.AIN ./ 256, r.channel, s.bipGain, s.resolution);
        r = rmfield(r, {'iotype', 'reserved'});
    end

    function value = ainCal_(ain, channel, gain, resolution)
        %select the calibration factor to use from the channel number and
        %gain. 'ain', 'channel', and 'gain' must all be the same size.
        if ~isequal(size(ain), size(channel), size(gain))
            error('LabJackUE9:badArguments', 'ain, channel, and gain must be the same size.');
        end
        
        %slope/offset
        s = struct('slope', cell(size(ain)), 'offset', cell(size(ain)));
        if resolution >= 18
            s(gain == 0) = calibration.ADCUnipolarHighRes;
            s(gain == 8) = calibration.ADCBipolarHighRes;
        else
            s(gain < 4) = calibration.ADCUnipolar(gain(gain < 4) + 1);
            s(gain == 8) = calibration.ADCBipolar;
        end
        s(channel == 132) = calibration.Vs;
        s(channel == 133) = calibration.temp;
        s(channel == 140) = calibration.Vs;
        s(channel == 141) = calibration.temp;
        if any(~cellfun('prodofsize', {s.slope}))
            error('LabJackUE9:invalidGainValue', 'invalid gain value for this resolution');
        end
            
        value = [double(ain(:)')] .* [s.slope] + [s.offset];
        value = reshape(value, size(ain));
    end

    SINGLEIO_ANALOGOUT_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_ ...
        , 'format', struct...
            ( 'iotype',         uint8(SINGLEIO_IOTYPE_.analogOut) ...
            , 'channel',        uint8(0) ...
            , 'DAC',       	    uint16(0) ...
            , 'reserved',       uint8([0 0]) ...
            ) ...
        , 'response', struct...
            ( 'iotype',         uint8(SINGLEIO_IOTYPE_.analogOut) ...
            , 'channel',        uint8(0) ...
            , 'DAC',       	    uint16(0) ...
            , 'reserved',       uint8([0 0]) ...
            ) ...
        );

    
    function r = voltageOut(channel, volts)
        %function r = analogOut(channel, volts)
        %
        %Sets a DAC value. 'channel' the channel number, 'voltage' in the
        %range [0,4.9] or so (will be approximated using the calibration
        %data and clipped to the available range.)
        %
        %Note that the labjack returns no data in its response.
        % 
        % >> a = LabJackUE9; require(a.init(), @()a.voltageOut(0, 4.0))
        % ans =
        %     channel: 0
        %         DAC: 0
        s.DAC = aoutcal_(channel, volts);
        
        r = roundtrip(SINGLEIO_ANALOGOUT_COMMAND_, s);        
        r = rmfield(r, {'iotype', 'reserved'});
    end
    
    function value = aoutcal_(channel, volts)
        value = round(volts * calibration.DAC(channel+1).slope + calibration.DAC(channel+1).offset);
        value = max(value, 0);
        value = min(value, 4095);
    end

    function r = analogOut(channel, value)
        %function r = analogOut(channel, value)
        %
        %Sets a DAC value. 'channel' the channel number, 'value'
        %ranging from 0 to 4095.
        %
        %Note that the labjack returns no data in its response.
        % 
        % >> a = LabJackUE9; require(a.init(), @()a.analogOut(0, 1024))
        % ans =
        %     channel: 0
        %         DAC: 0
        
        s = SINGLEIO_ANALOGOUT_COMMAND_.format;
        s.DAC = value;
        r = roundtrip(SINGLEIO_ANALOGOUT_COMMAND_, s);        
        r = rmfield(r, {'iotype', 'reserved'});
    end


    SINGLEIO_PORT_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_ ...
        , 'format', struct...
            ( 'iotype',     uint8(SINGLEIO_IOTYPE_.digitalPortRead) ...
            , 'channel',    uint8(0) ...
            , 'dir',        false(1, 8)...       %false for input, true for output
            , 'state',      false(1, 8) ...
            , 'reserved',       uint8([0 0]) ...
            )...
        , 'response', struct...
            ( 'iotype',     uint8(0) ...
            , 'channel',    uint8(0) ...
            , 'dir',        false(1, 8) ...
            , 'state',      false(1, 8) ...
            , 'reserved',       uint8([0 0]) ...
            )...
        );

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
        
        s = SINGLEIO_PORT_COMMAND_.format;
        
        s.iotype = SINGLEIO_IOTYPE_.digitalPortRead;
        s.channel = channel;
        
        r = roundtrip(SINGLEIO_PORT_COMMAND_, s);
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
        
        s = SINGLEIO_PORT_COMMAND_.format;

        s.iotype = SINGLEIO_IOTYPE_.digitalPortWrite;
        s.channel = channel;
        s.dir = dir;
        s.state = state;
        
        r = roundtrip(SINGLEIO_PORT_COMMAND_, s);
        r = rmfield(r, {'iotype', 'reserved'});
    end

%% TimerCounter
TIMERCOUNTER_TIMERSPEC_ = struct...
    'mode', struct('enum_', uint8(0)...
        , 'PWM16', 0 ...
        , 'PWM8', 1 ...
        , 'Rising32', 2 ...
        , 'Falling32', 3 ...
        , 'DutyCycle', 4 ...
        , 'FirmwareCounter', 5 ...
        , 'FirmwareCounterDebounce', 6 ...
        , 'Frequency', 7 ...
        , 'Quadrature', 8 ...
        , 'TimerStop', 9 ...
        , 'SystemTimerLowRead', 10 ...
        , 'SystemTimerHighRead', 11 ...
        , 'Rising16' 12 ...
        , 'Falling16' 13 ...
        )...
    'value', uint16(0)...
    };

TIMERCOUNTER_COMMAND_ = struct...
    ( 'extended', 1 ...
    , 'commandNo', 24 ...
    , 'format', struct ...
        ( 'TimerClockDivisor', uint8(0)...
        , 'EnableMask', struct...
            ( 'NumTimers', true(3, 1)...
            , 'Counter0', false ...
            , 'Counter1', false ...
            , 'reserved0', false(1, 2)...
            , 'UpdateConfig', false ...
            )...
        , 'TimerClockBase', true... %just the LSB
        , 'reserved0', false(1, 7)...
        , 'UpdateReset', struct ...
            ( 'Timer0', false ...
            , 'Timer1', false ...
            , 'Timer2', false ...
            , 'Timer3', false ...
            , 'Timer4', false ...
            , 'Timer5', false ...
            , 'Counter0', false ...
            , 'Counter1', false ...
            )...
        , 'Timer0', TIMERCOUNTER_TIMERSPEC_...
        , 'Timer1', TIMERCOUNTER_TIMERSPEC_...
        , 'Timer2', TIMERCOUNTER_TIMERSPEC_...
        , 'Timer3', TIMERCOUNTER_TIMERSPEC_...
        , 'Timer4', TIMERCOUNTER_TIMERSPEC_...
        , 'Timer5', TIMERCOUNTER_TIMERSPEC_...
        )...
    , 'response', struct...
        (...
        )...
    );
        

%% Reset
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

%% ReadMem & LoadCalibration
    READMEM_COMMAND_ = struct...
        ( 'extended', 1 ...
        , 'commandNo',  42 ...
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
        if blocknum < 0 || blocknum > 15
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

    %we have a wacky 64 bit point data type for calibration...
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
            , 'offset', {Z_} ) ...        %there's a zero here acutally
        , 'tempLow', struct...
            ( 'slope', {Z_} ...
            , 'offset', {Z_} ) ...        %not used
        , 'CalTemp',                         Z_ ...
        , 'Vref',                            Z_ ...
        , 'reserved2',                       Z_ ...
        , 'HalfVref',                        Z_ ...
        , 'Vs', struct...
            ( 'slope', {Z_} ...
            , 'offset', {Z_} ) ...        %not used
        , 'reserved3',                      zeros(16, 1, 'uint8')    ...
        , 'ADCUnipolarHighRes',  struct...
            ( 'slope', {Z_} ...
            , 'offset', {Z_} ) ...
        , 'reserved4',                      zeros(112, 1, 'uint8') ...
        , 'ADCBipolarHighRes', struct...
            ( 'slope', {Z_} ...
            , 'offset', {Z_} ) ...
        , 'reserved5',                      zeros(112, 1, 'uint8') ...
        );

    function c = loadCalibration()
        for i = 0:4
            block(i+1) = readMem(i);
            block(i+1).data = block(i+1).data(:)';
        end
        
        c = frombytes([block.data], CALIBRATION_FORMAT_, 'littleendian', 1);
        c = rmfield(c, strcat('reserved', ['012345']'));
        c = unfix(c);
        calibration = c;

        function c = unfix(c)
            switch class(c)
                case 'struct'
                    if numel(c) ~= 1
                        c = arrayfun(@unfix, c);
                    elseif all(isfield(c, {'frac', 'int'}))
                        c = arrayfun(@(s)double(s.int) + double(s.frac) / 2^32, c);
                    else
                        c = structfun(@unfix, c, 'UniformOutput', 0);
                    end
                case 'cell'
                    c = cellfun(@unfix, c, 'UniformOutput', 0);
                otherwise
                    c = c;
            end
        end
    end

%% WriteMem
    WRITEMEM_COMMAND_ = struct...
        ( 'extended', 1 ...
        , 'commandNo', 40 ...
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

%% Communications

    function response = roundtrip(command, data)
        remote = 1;
        extended = 0;
        
        if isfield(command, 'extended')
            extended = command.extended;
        end
        if isfield(command, 'remote')
            remote = command.remote;
        end

        sendPacket(command.commandNo, tobytes(command.format, data, LE_), remote, extended);
        [commandNo, response] = readPacket();
        if ~isequal(commandNo, command.commandNo)
            error('LabJackUE9:mismatchedCommandNumbers', 'response command number %d from command %d', commandNo, command.commandNo);
        end
            
        response = frombytes(response, command.response, LE_);
    end
    
    function initializer = init(varargin)
        
        initializer = joinResource...
            ( openPort(portA, @setA)...
            , openPort(portB, @setB)...
            , @setOpen ...
            , @getCal ...
            );

        initializer = currynamedargs(initializer, varargin{:});
        
        function opener = openPort(port, setter)
            opener = @i;
            function [release, params] = i(params)
                assertNotOpen_();
                handle = pnet('tcpconnect', host, portA); %does port matter?
                if handle < 0
                    error('LabJackUE9:connection', 'Could not connect');
                end
                pnet(handle, 'setreadtimeout', readTimeout);
                pnet(handle, 'setwritetimeout', writeTimeout);
                setter(handle);
                
                release = @close;
                function close()
                    pnet(handle, 'close');
                end
            end
        end
        
        function setA(a)
            a_ = a;
        end

        function setB(b)
            b_ = b;
        end
        
        function [release, params] = setOpen(params)
            open = 1;
            release = @close;
            function close()
                open = 0;
            end
        end
        
        function [release, params] = getCal(params)
            flush();
            require(@debugOff, @loadCalibration);
            release = @noop;
        end
        
        function [release, params] = debugOff(params)
            old = debug;
            debug = 0;
            release = @x;
            function x()
                debug = old;
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
        pnet(a_, 'write', uint8([8 8]));
        resp = pnet(a_, 'read', 2, 'uint8');
        if ~isequal([8 8], resp)
            error('LabJackUE9:flushFailed', 'flush operation failed')
        end
        pnet(a_, 'read', 'noblock');
        pnet(b_, 'read', 'noblock');
    end
    

    function [commandNo, data] = readPacket(conn)
        if nargin == 0
            conn = a_;
        end
        
        in = pnet(conn, 'read', 2, 'uint8');
        if numel(in) < 2
            error('LabJackUE9:ReadTimeOut', 'packet read timeout');
        end
        cksumin = in(1);
        commandByte = in(2);
        commandNo = bitand(15, bitshift(in(2), -3));
        if commandByte == 184 %checksum error
            dataLength = 0;
        elseif commandNo <= 14
            dataLength = bitand(in(2), 3);
        else
            dataLength = 2;
        end
        
        data = pnet(conn, 'read', dataLength*2, 'uint8');
        if numel(data) < dataLength*2
            error('LabJackUE9:ReadTimeOut', 'packet read timeout');
        end
        cksum = sum(double([in(2) data]));
        cksum = mod(cksum, 256) + floor(cksum/256);
        cksum = mod(cksum, 256) + floor(cksum/256);
        if cksum ~= cksumin
            error('LabJackUE9:checksum','Packet read checksum failure')
        end
        
        if commandNo > 14
            xDataLength = data(1);
            xCommandNo = data(2);
            xCksuminL = data(3);
            xCksuminH = data(4);
            xData = pnet(conn, 'read', xDataLength*2, 'uint8');
            if numel(xData) < xDataLength*2
                error('LabJackUE9:ReadTimeOut', 'packet read timeout');
            end
            
            xCksum = sum(double(xData));
            if xCksum ~= double(xCksuminH)*256 + double(xCksuminL)
                error('LabJackUE9:checksum','Packet read extended checksum failure');
            end
            data = xData;
            commandNo = xCommandNo;
            
        else
            xData = [];
        end
        
        if debug
            disp(strcat('<<< ', hexdump([in data xData])));
        end
            
    end

    
    function sendPacket(commandNo, data, remote, extended)
        if nargin < 3
            remote = 1;
        end
        if nargin < 4
            extended = 0;
        end
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
            data = [mod(data(:)', 256); floor(data(:)'/256)]';
            data = data(:)';
        end
    
        cksum2 = sum(data);

        if mod(numel(data), 2)
            error('LabJackUE9:unevenData', 'Must provide an even number of bytes.');
        end

        if commandNo <= 14 && ~extended
            %normal command
            if numel(data) <= 28
                cbyte = 128*logical(remote) + bitand(commandNo,15)*8 + bitand(numel(data)/2,7);
                cksum = sum([cbyte data]);
                cksum = mod(cksum, 256) + floor(cksum/256); %ones complement accumulator
                packet = uint8([cksum, cbyte, data]);
            else
                error('LabJackUE9:TooMuchData', 'Too much data for this command.');
            end
        else
            %extended command
            if numel(data) <= 500
                cbyte = 128 * logical(remote) + 120;
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
        
        if debug
            disp(strcat('>>> ', hexdump(packet)));
        end

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