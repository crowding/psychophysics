function this = LabJackUE9(varargin)
%An object that interfaces to the LabJack UE9 over TCP.
%
%Type 'hel LabJackUE9' to see a list of properties and methods.

%hey here's the command to see what's goping on behind the scenes!
%sudo tcpdump -i en1 -X port 52360 or port 52361

host = '100.1.1.3'; %Address of the device.
portA = 52360; %The control command port
portB = 52361; %The streaming port
readTimeout = 0.2; %the TCP read timeout in seconds.
writeTimeout = 0.2; %the TCP write timeout in seconds.
discoveryTimeout = 1; %the UDP discovery timeout in seconds.
debug = 0; %If set, will print out a hex dump of all communications
debugstream = 0; %controls stream debugging separately
maxBacklog = 4096;   %how many orphan samples to keep during streaming

open_ = 0; %Indicates whether we are open.

persistent LE_;
LE_ = struct('littleendian', 1);

%Calibration params. These are copied from my personal labjack. Values from
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
calibration.Vsupply.slope = 9.26947686821222e-05;
calibration.Vsupply.offset = 0;
calibration.ADCUnipolarHighRes.slope = -2.3283064365387e-10;
calibration.ADCUnipolarHighRes.offset = -2.3283064365387e-10;
calibration.ADCBipolarHighRes.slope = -2.3283064365387e-10;
calibration.ADCBipolarHighRes.offset = -2.3283064365387e-10;

a_ = []; %TCP connection port handle
b_ = [];

persistent init__; %#ok
this = autoobject(varargin{:});
persistent ERRORCODE_;
    ERRORCODE_ =    enum(uint8(0) ...
        , 'NOERROR', 0 ... 
        , 'SCRATCH_WRT_FAIL',  1 ...
        , 'SCRATCH_ERASE_FAIL', 2 ...
        , 'DATA_BUFFER_OVERFLOW',  3 ...
        , 'ADC0_BUFFER_OVERFLOW',  4 ...
        , 'FUNCTION_INVALID',  5 ...
        , 'SWDT_TIME_INVALID',  6 ...
        , 'FLASH_WRITE_FAIL',  16 ...
        , 'FLASH_ERASE_FAIL',  17 ...
        , 'FLASH_JMP_FAIL',  18 ...
        , 'FLASH_PSP_TIMEOUT',  19 ...
        , 'FLASH_ABORT_RECEIVED',  20 ...
        , 'FLASH_PAGE_MISMATCH',  21 ...
        , 'FLASH_BLOCK_MISMATCH',  22 ...
        , 'FLASH_PAGE_NOT_IN_CODE_AREA',  23 ...
        , 'MEM_ILLEGAL_ADDRESS',  24 ...
        , 'FLASH_LOCKED',  25 ...
        , 'INVALID_BLOCK',  26 ...
        , 'FLASH_ILLEGAL_PAGE',  27 ...
        , 'STREAM_IS_ACTIVE',  48 ...
        , 'STREAM_TABLE_INVALID',  49 ...
        , 'STREAM_CONFIG_INVALID',  50 ...
        , 'STREAM_BAD_TRIGGER_SOURCE', 51 ...
        , 'STREAM_NOT_RUNNING',  52 ...
        , 'STREAM_INVALID_TRIGGER',  53 ...
        , 'STREAM_CONTROL_BUFFER_OVERFLOW',  54 ...
        , 'STREAM_SCAN_OVERLAP',  55 ...
        , 'STREAM_SAMPLE_NUM_INVALID',  56 ...
        , 'STREAM_BIPOLAR_GAIN_INVALID',  57 ...
        , 'STREAM_SCAN_RATE_INVALID',  58 ...
        , 'TIMER_INVALID_MODE',  64 ...
        , 'TIMER_QUADRATURE_AB_ERROR',  65 ...
        , 'TIMER_QUAD_PULSE_SEQUENCE',  66 ...
        , 'TIMER_BAD_CLOCK_SOURCE',  67 ...
        , 'TIMER_STREAM_ACTIVE',  68 ...
        , 'TIMER_PWMSTOP_MODULE_ERROR',  69 ...
        , 'EXT_OSC_NOT_STABLE',  80 ...
        , 'INVALID_POWER_SETTING',  81 ...
        , 'PLL_NOT_LOCKED',  82 ...
        );
    
    function setReadTimeout(t)
        assertNotOpen_();
        readTimeout = t;
    end

    function setWriteTimeout(t)
        assertNotOpen_();
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

    function setCalibration(c)
        calibration = c;
        updateSpecialCalibrations_(); %maintain the lookup table used when applying calibrations.
    end

    function IP = getIPAddress()
        assertOpen_();
        IP = pnet(a_, 'gethost');
    end

    %------ COMMANDS ------
    
%% CommConfig

persistent COMMCONFIG_COMMAND_;
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

    function response = commConfig(varargin)
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
        response = flipaddress_(response); %we usually see IP/MAC addresses as big endian
    end

%% DiscoveryUDP
persistent UDP_DISCOVERY_PORT_;
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
                discovery(end+1) = frombytes(payload, COMMCONFIG_COMMAND_.response); %#ok, 
                %since I don't know how far it will grow, preallocation is pointless!
                %fuckin' MATLAB with no vectors or normal data
                %structures...
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
persistent CONTROLCONFIG_COMMAND_;
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
        %
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

    %names for the analog channels
    persistent args_;
    args_ = cat(1 ...
        , arrayfun(@(x)sprintf('AIN%d', x), [0:13 16:127], 'UniformOutput', 0) ...
        , num2cell([0:13 16:127]) ...
    );

    persistent ANALOG_IN_CHANNEL_;
    ANALOG_IN_CHANNEL_ = enum(uint8(0)...
        , 'Vref',       14 ...
        , 'GND',        15 ...
        , 'Vref',       128 ...
        , 'Vsupply',    132 ...
        , 'Temp',       133 ...
        , 'GND',        136 ...
        , 'Vsupply',    140 ...
        , 'Temp',       141 ...
        , 'EIO_FIO',    193 ...
        , 'MIO_CIO',    194 ...
        , 'Timer0',     200 ...
        , 'Timer1',     201 ...
        , 'Timer2',     202 ...
        , 'Timer3',     203 ...
        , 'Timer4',     204 ...
        , 'Timer5',     205 ...
        , 'Counter0',   210 ...
        , 'TC_Capture', 210 ...
        , args_{:} ...
        );
    
    persistent ANALOG_IN_GAIN_
    ANALOG_IN_GAIN_ = enum(uint8(0)...
        ,'x1', 0 ...
        ,'x2', 1 ...
        ,'x4', 2 ...
        ,'x8', 3 ...
        ,'Bipolar', 8 ...
        );

    persistent FEEDBACK_COMMAND_
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
            , 'AINGain',            setfield(ANALOG_IN_GAIN_, 'enum_', true(4, 16))...
            )...
        , 'response', struct...
            ( 'FIODir',             false(1, 8)...
            , 'FIOState',           false(1, 8)...
            , 'EIODir',             false(1, 8)...
            , 'EIOState',           false(1, 8)...
            , 'CIOState',           false(1, 4)...
            , 'CIODir',             false(1, 4)...
            , 'MIOState',           false(1, 3)...
            , 'reserved0',          false...
            , 'MIODir',             false(1, 3)...
            , 'reserved1',          false...
            , 'AIN',                uint16(zeros(1, 16))...
            , 'Counter0',           uint16(0)...
            , 'Counter1',           uint16(0)...
            , 'TimerA',             uint16(0)...
            , 'TimerB',             uint16(0)...
            , 'TimerC',             uint16(0)...
            )...
        ); %#ok

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
        %appropriate numbers or names to read internal channels.
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
        
        r = rmfield(r, {'reserved0', 'reserved1'});
    end

    persistent FEEDBACKALT_COMMAND_;
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
            , 'AIN14ChannelNumber', uint8(0)...
            , 'AIN15ChannelNumber', uint8(0)...
            , 'Resolution',         uint8(0)...
            , 'SettlingTime',       uint8(0)...
            , 'AINGain',            setfield(ANALOG_IN_GAIN_, 'enum_', true(4, 16))...
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
            , 'reserved0',          false...
            , 'MIODir',             false(1, 3)...
            , 'reserved1',          false...
            , 'AIN',                uint16(zeros(1, 16))...
            )...
        ); %#ok

    function r = feedbackAlt(varargin)
        %Like 'Feedback' except that there is a 'AINChannelNumber' parameter that
        %takes a 16-element array; it allows you to redirect all 16
        %channel samplings. You can provide 
        
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
                    args.AINChannelNumber = enumToNumber(args.AINChannelNumber, ANALOG_IN_CHANNEL_);
                    
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

        r = roundtrip(FEEDBACKALT_COMMAND_, packet, 'enum', 0);
        
        %calibrate the analog reads
        c14 = enumToNumber(packet.AIN14ChannelNumber, ANALOG_IN_CHANNEL_);
        c15 = enumToNumber(packet.AIN15ChannelNumber, ANALOG_IN_CHANNEL_);
        channel = [packet.AINChannelNumber(:)' c14 c15];
        r.AINValue = ainCal_(r.AIN(:), channel(:), packet.AINGain(:), packet.Resolution);

        r = rmfield(r, {'reserved0', 'reserved1'});
    end

%% SingleIO: bit i/o
    persistent SINGLEIO_COMMAND_;
    SINGLEIO_COMMAND_ = 4;
    
    persistent SINGLEIO_IOTYPE_;
    SINGLEIO_IOTYPE_ = enum(uint8(0) ...
        , 'DigitalBitRead',     0 ...
        , 'DigitalBitWrite',    1 ...
        , 'DigitalPortRead',    2 ...
        , 'DigitalPortWrite',   3 ...
        , 'AnalogIn',           4 ...
        , 'AnalogOut',          5 ...
        );
    
    persistent SINGLEIO_DIR_;
    SINGLEIO_DIR_ = enum(false ...
        , 'in',  0 ...
        , 'out', 1 ...
        );
    
    persistent DIGITAL_IO_CHANNEL_;
    DIGITAL_IO_CHANNEL_ = enum(uint8(0) ...
        , 'FIO0', 0 ...
        , 'FIO1', 1 ...
        , 'FIO2', 2 ...
        , 'FIO3', 3 ...
        , 'FIO4', 4 ...
        , 'FIO5', 5 ...
        , 'FIO6', 6 ...
        , 'FIO7', 7 ...
        , 'EIO0', 8 ...
        , 'EIO1', 9 ...
        , 'EIO2', 10 ...
        , 'EIO3', 11 ...
        , 'EIO4', 12 ...
        , 'EIO5', 13 ...
        , 'EIO6', 14 ...
        , 'EIO7', 15 ...
        , 'CIO0', 16 ...
        , 'CIO1', 17 ...
        , 'CIO2', 18 ...
        , 'CIO3', 19 ...
        , 'MIO0', 20 ...        
        , 'MIO1', 21 ...        
        , 'MIO2', 22 ...
        );

    persistent SINGLEIO_BIT_COMMAND_;
    SINGLEIO_BIT_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_ ...
        , 'format', struct...
            ( 'iotype',     SINGLEIO_IOTYPE_ ...
            , 'channel',    DIGITAL_IO_CHANNEL_ ...
            , 'dir',        SINGLEIO_DIR_ ...       %false for input, true for output
            , 'reserved0',  false(1, 7) ...
            , 'state',      false ...
            , 'reserved1',  false(1, 23) ...
            )...
        , 'response', struct...
            ( 'iotype',     SINGLEIO_IOTYPE_ ...
            , 'channel',    DIGITAL_IO_CHANNEL_ ...
            , 'dir',        SINGLEIO_DIR_ ...
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
        
        s.iotype = 'DigitalBitRead';
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
        %
        %The channels are numbered as follows:
        %0..7 FIO0..7
        %
        assertOpen_();
        
        s = SINGLEIO_BIT_COMMAND_.format;
        
        s.iotype = 'DigitalBitWrite';
        s.channel = channel;
        s.dir = dir;
        s.state = state;
        
        r = roundtrip(SINGLEIO_BIT_COMMAND_, s);
        r = rmfield(r, {'iotype', 'reserved0', 'reserved1'});
    end
        
%% SingleIO: analog in

    persistent SINGLEIO_ANALOGIN_COMMAND_;
    SINGLEIO_ANALOGIN_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_...
        , 'format', struct...
            ( 'iotype',         uint8(SINGLEIO_IOTYPE_.AnalogIn) ...
            , 'channel',        ANALOG_IN_CHANNEL_ ...
            , 'bipGain',        ANALOG_IN_GAIN_ ...
            , 'resolution',     uint8(16) ...
            , 'settlingTime',   uint8(0) ...
            , 'reserved',       uint8(0) ...
            ) ...
        , 'response',  struct...
            ( 'iotype',         SINGLEIO_IOTYPE_ ...
            , 'channel',        ANALOG_IN_CHANNEL_ ...
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
        %8 : [-5,5]v. Default 0. You can slo use text labels 'x1', 'x2',
        %'x4, 'x8', and 'Bipolar.'
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
        r.value = ainCal_(r.AIN ./ 256, s.channel, s.bipGain, s.resolution);
        r = rmfield(r, {'iotype', 'reserved'});
    end


    function value = ainCal_(ain, channel, gain, resolution)
        %select the calibration factor to use from the channel number and
        %gain. 'ain', 'channel', and 'gain' must all be the same size.
        channel = enumToNumber(channel, ANALOG_IN_CHANNEL_);
        gain = enumToNumber(gain, ANALOG_IN_GAIN_);
        
        if ~isequal(size(ain), size(channel), size(gain))
            error('LabJackUE9:badArguments', 'ain, channel, and gain must be the same size.');
        end
        
        %slope/offset
        [slope, offset] = findSlopeOffset_(channel, gain, resolution);
            
        value = double(ain(:)) .* slope(:) + offset(:);
        value = reshape(value, size(ain));
    end

    %findSlopeOffset looks in this lookup table for the 'special'
    %calibration values.
    persistent specialChannels_;
    specialChannels_ = [];
    
    persistent specialCalibrations_;
    specialCalibrations_ = struct('slope', {}, 'offset', {});
    function updateSpecialCalibrations_()
        sc = [132 133 140 141 193 194 200 201 202 203 204 205 210 224];
        
        CALIBRATION_RAW_ = struct('slope', 1, 'offset', 0);
        specialChannels_ = false(1, 256);
        specialCalibrations_ = struct('slope', cell(1, 256), 'offset', cell(1, 256));
        specialChannels_(sc+1) = true;
        specialCalibrations_(sc+1) = ...
            [ calibration.Vsupply...
            , calibration.temp ...
            , calibration.Vsupply...
            , calibration.temp ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            , CALIBRATION_RAW_ ...
            ];
    end
    updateSpecialCalibrations_();

    function [slope, offset] = findSlopeOffset_(channel, gain, resolution)
        s = struct('slope', cell(size(channel)), 'offset', cell(size(channel)));
        if resolution >= 18
            s(gain == 0) = calibration.ADCUnipolarHighRes;
            s(gain == 8) = calibration.ADCBipolarHighRes;
        else
            s(gain < 4) = calibration.ADCUnipolar(gain(gain < 4) + 1);
            s(gain == 8) = calibration.ADCBipolar;
        end
        
        %lookup special channels that bypass normal signal acquisition
        s(specialChannels_(channel+1)) = specialCalibrations_(channel(specialChannels_(channel+1))+1);
        
        if any(~cellfun('prodofsize', {s.slope}))
            error('LabJackUE9:invalidGainValue', 'invalid gain value for this resolution');
        end
        slope = reshape([s.slope], size(channel));
        offset = reshape([s.offset], size(channel));
    end

%% SingleIO: Analog out
    persistent ANALOG_OUT_CHANNEL_;
    ANALOG_OUT_CHANNEL_ = enum(uint8(0)...
        , 'DAC0', 0 ...
        , 'DAC1', 1 ...
        );

    persistent SINGLEIO_ANALOGOUT_COMMAND_;
    SINGLEIO_ANALOGOUT_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_ ...
        , 'format', struct...
            ( 'iotype',         uint8(SINGLEIO_IOTYPE_.AnalogOut) ...
            , 'channel',        ANALOG_OUT_CHANNEL_ ...
            , 'DAC',       	    uint16(0) ...
            , 'reserved',       uint8([0 0]) ...
            ) ...
        , 'response', struct...
            ( 'iotype',         SINGLEIO_IOTYPE_ ...
            , 'channel',        ANALOG_OUT_CHANNEL_ ...
            , 'DAC',       	    uint16(0) ...
            , 'reserved',       uint8([0 0]) ...
            ) ...
        );

    
    function r = voltageOut(channel, volts)
        %function r = analogOut(channel, volts)
        %
        %Sets a DAC value. 'channel' the channel number or name, 'voltage' in the
        %range [0,4.9] or so (will be approximated using the calibration
        %data and clipped to the available range.)
        %
        %Note that the labjack returns no data in its response.
        % 
        % >> a = LabJackUE9; require(a.init(), @()a.voltageOut(0, 4.0))
        % ans =
        %     channel: 0
        %         DAC: 0
        s.channel = channel;
        s.DAC = aoutcal_(channel, volts);
        
        r = roundtrip(SINGLEIO_ANALOGOUT_COMMAND_, s);        
        r = rmfield(r, {'iotype', 'reserved'});
    end
    
    function value = aoutcal_(channel, volts)
        channel = enumToNumber(channel, ANALOG_OUT_CHANNEL_);
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
        s.channel = channel;
        s.DAC = value;
        r = roundtrip(SINGLEIO_ANALOGOUT_COMMAND_, s);        
        r = rmfield(r, {'iotype', 'reserved'});
    end

%% SingleIO: digital port i/o

    persistent DIGITAL_IO_PORT_;
    DIGITAL_IO_PORT_ = enum(uint8(0) ...
        , 'FIO', 0 ...
        , 'EIO', 1 ...
        , 'CIO', 2 ...
        , 'MIO', 3 ...
        );

    persistent SINGLEIO_PORT_COMMAND_;
    SINGLEIO_PORT_COMMAND_ = struct...
        ( 'extended', 0 ...
        , 'commandNo', SINGLEIO_COMMAND_ ...
        , 'format', struct...
            ( 'iotype',     uint8(SINGLEIO_IOTYPE_.DigitalPortRead) ...
            , 'port',       DIGITAL_IO_PORT_ ...
            , 'dir',        false(8, 1)...       %false for input, true for output
            , 'state',      false(8, 1) ...
            , 'reserved',       uint8([0 0]) ...
            )...
        , 'response', struct...
            ( 'iotype',     SINGLEIO_IOTYPE_ ...
            , 'port',       DIGITAL_IO_PORT_ ...
            , 'dir',        false(1, 8) ...
            , 'state',      false(1, 8) ...
            , 'reserved',   uint8([0 0]) ...
            )...
        );

    function r = portIn(port)
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
        
        s.iotype = SINGLEIO_IOTYPE_.DigitalPortRead;
        s.port = port;
        
        r = roundtrip(SINGLEIO_PORT_COMMAND_, s);
        r = rmfield(r, {'iotype', 'reserved'});
    end


    function r = portOut(port, dir, state)
        %function r = portIn(channel)
        %Sets the state of the digital IO port specified. 
        %   Ports are 0: FIO, 1: EIO, 2, CIO, 3, MIO.
        %
        % Note that 8 bit inputs are expected even if the M anc D ports
        % have fewer.
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

        s.iotype = SINGLEIO_IOTYPE_.DigitalPortWrite;
        s.port = port;
        s.dir = dir;
        s.state = state;
        
        r = roundtrip(SINGLEIO_PORT_COMMAND_, s);
        r = rmfield(r, {'iotype', 'reserved'});
    end

%% TimerCounter
    persistent TIMERCOUNTER_TIMERSPEC_;
    TIMERCOUNTER_TIMERSPEC_ = struct...
        ( 'Mode', enum(uint8(0)...
            , 'PWM16',                      0 ...
            , 'PWM8',                       1 ...
            , 'Rising32',                   2 ...
            , 'Falling32',                  3 ...
            , 'DutyCycle',                  4 ...
            , 'FirmwareCounter',            5 ...
            , 'FirmwareCounterDebounce',    6 ...
            , 'Frequency',                  7 ...
            , 'Quadrature',                 8 ...
            , 'TimerStop',                  9 ...
            , 'SystemTimerLow',         10 ...
            , 'SystemTimerHigh',        11 ...
            , 'Rising16',                   12 ...
            , 'Falling16',                  13 ...
            ) ...
        , 'Value', uint16(0)...
        );

    persistent TIMERCOUNTER_COMMAND_;
    TIMERCOUNTER_COMMAND_ = struct...
        ( 'extended', 1 ...
        , 'commandNo', 24 ...
        , 'format', struct ...
            ( 'TimerClockDivisor', uint8(1)...
            , 'NumTimers', false(3, 1)...
            , 'Counter0Enabled', false ...
            , 'Counter1Enabled', false ...
            , 'reserved0', false(1, 2)...
            , 'UpdateConfig', false ...
            , 'TimerClockBase', enum(uint8(1)...
                , 'M48', 1 ...
                , 'K750', 0 ...
                )...
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
            , 'Counter0Mode', uint8(0)... %no effect
            , 'Counter1Mode', uint8(0)... %no effect
            )...
        , 'response', struct...
            ( 'errorcode',  ERRORCODE_...
            , 'reserved0',  uint8(0)...
            , 'Timer0',     uint32(0)...
            , 'Timer1',     uint32(0)...
            , 'Timer2',     uint32(0)...
            , 'Timer3',     uint32(0)...
            , 'Timer4',     uint32(0)...
            , 'Timer5',     uint32(0)...
            , 'Counter0',   uint32(0)...
            , 'Counter1',   uint32(0)...
            )...
        );
        

    function r = timerCounter(varargin)
        %Configure the timers. Takes a list of name/value pairs (or
        %equivalent structures.)
        %
        %To set the number of active timers give a value to 'NumTimers'.
        %
        %To enable or disable the counters give boolean values to
        %'Counter0Enabled' or 'Counter1Enabled.'
        %
        %Pass ('TimerClockBase', 0) or ('TimerCounter', 'K750') to use the
        %750 Khz clock, and 1 or 'System' to use the system clock (48 MHz
        %unless in low power mode). Defaults to the system clock
        %
        %If using any of the above, 'UpdateConfig' will be set for you (so if
        %setting the clock base, also enable the timers and counters and set\
        %the timer modes in the same command!)
        %
        %To update the timer mode pass a value to 'TimerX.Mode' where X is
        %from 0 to 5. The mode can be an integer or a name from the enumeration:
        %
        % PWM16                      0
        % PWM8                       1
        % Rising32                   2
        % Falling32                  3
        % DutyCycle                  4
        % FirmwareCounter            5
        % FirmwareCounterDebounce    6
        % Frequency                  7
        % Quadrature                 8
        % TimerStop                  9
        % SystemTimerLowRead         10
        % SystemTimerHighRead        11
        % Rising16                   12
        % Falling16                  13
        %
        % To set the timer values pass a value to 'TimerX.Value'
        %
        % For convenience, the UpdateReset bits will be set true for you if
        % you provide any TimerX.Mode or TimerX.Value arguments. (This
        % means provide both Mode and Value at the same time, else they
        % default to 0.
        %
        % You can override UpdateReset by providing arguments named
        % 'UpdateReset.TimerX'.
        %
        % To reset the hardware counters, pass a true value to
        % 'UpdateReset.Counter0' or 'UpdateReset.Counter1'. 
        assertOpen_();

        packet = TIMERCOUNTER_COMMAND_.format;
        
        args = namedargs(varargin{:});
        
        if any(isfield(args, {'NumTimers', 'Counter0Enabled', 'Counter1Enabled', 'TimerClockDivisor'})) && ~isfield(args, 'UpdateConfig')
            packet.UpdateConfig = 1;
        end
        
        for i = 0:5
            tname = sprintf('Timer%d', i);
            if isfield(args, tname)
                if isfield(args.(tname), 'Mode')
                    packet.NumTimers = i+1;
                    packet.UpdateConfig = 1;
                end
                if isfield(args.(tname), 'Value')
                    packet.UpdateReset.(tname) = 1;
                end
            end
        end
        
        packet = namedargs(packet, args);
        
        r = roundtrip(TIMERCOUNTER_COMMAND_, packet);
        r = rmfield(r, 'reserved0');
    end

%% StreamConfig
    persistent STREAM_CLOCK_FREQUENCY_;
    STREAM_CLOCK_FREQUENCY_ = enum(true(2, 1) ...
        , 'M4', 0 ...
        , 'M48', 1 ...
        , 'k750', 2 ...
        , 'M24', 3 ...
        );

    persistent STREAMCONFIG_COMMAND_;
    STREAMCONFIG_COMMAND_ = struct...
        ( 'extended', 1 ...
        , 'commandNo', 17 ...
        , 'format', struct...
            ( 'NumChannels', uint8(0) ...
            , 'Resolution', uint8(16) ...
            , 'SettlingTime', uint8(0) ...
            , 'reserved0', false ...
            , 'DivideBy256', false ...
            , 'reserved1', false ...
            , 'ClockFrequency', STREAM_CLOCK_FREQUENCY_ ...
            , 'reserved2', false ...
            , 'TriggerEnabled', false ...
            , 'PulseEnabled', false ...
            , 'ScanInterval', uint16(65535) ...
            , 'ChannelConfig', uint8([])... %to be filled out
            ) ...
        , 'response', struct...
            ( 'errorcode', ERRORCODE_ ...
            , 'reserved0', uint8(0)...
            )...
        );
    
    
    %private state variables used during stream operations.
    fNominal_ = [];
    tBegin_ = [];
    lastserial_ = [];

    incompleteSamples_ = [];
    incompleteChannels_ = [];
    incompleteData_ = [];
    
    warnDataLoss_ = 0;
    
    serialOffset_ = 0;
    
    configured_ = 0;
    calibrationSlope_ = 0; %will be a column vector...
    calibrationOffset_ = 0; %should be a column vector...
    
    function r = streamConfig(varargin)
        %Configures the LabJack for streamimg. 
        %
        %Optional arguments are passed as name/value pairs:
        %
        % 'Channels', an array of up to 128 channel numbers or a cell
        % arrray of channel names. Required.
        % 'Gains', an array of gains or cell array of strings; must have
        %   an equal number of elements as Channels. See under AnalogIn
        %   for the values. Required.
        % 'Resolution', the sampling resolution for all channels. Default
        %   is 12.
        % 'SettlingTime', the settling time. See AnalogIn.
        % 'TriggerEnabled', enables the external trigger (scans on falling
        %   edge of the Counter1 input)
        % 'PulseEnabled', pulses Counter1 output low before each scan.
        % 'SampleFrequency' A sample frequency in Hz. If this is provided
        %   the function will configure a sampling frequency to suit. The
        %   frequency chosen is returned in the SamplingFrequency
        %   field of the output.
        % 
        % If you wish to configure the sampling rate manually, you can
        % provide these arguments:
        % 'ClockFrequency', one of 'M4', 'M48', 'k750', or 'M24'.
        % 'DivideBy256', divides the stream clock by 256.
        % 'ScanInterval', value from 0-65535.
        %
        % In any case the nominal sample frequency will be found in the
        % SampleFrequency field of the result.
        
        assertOpen_();
        configured_ = 0;
        
        packet = STREAMCONFIG_COMMAND_.format;
        args = namedargs('Resolution', 12, varargin{:});
        
        if ~all(isfield(args, {'Channels', 'Gains'}))
            error('LabJackUE9:MissingArguments', 'Channels and Gains must be provided');
        end
        
        args.Channels = enumToNumber(args.Channels, ANALOG_IN_CHANNEL_);
        args.Gains = enumToNumber(args.Gains, ANALOG_IN_GAIN_);
        
        nc = numel(args.Channels);
        if nc < 0 || nc > 128 || nc ~= numel(args.Gains)
            error('LabJackUE9:BadArgs', 'channels and gains must be the same size and <= 128 elements');
        end
        
        packet.ChannelConfig = uint8([args.Channels(:)'; args.Gains(:)']);
        packet.NumChannels = numel(args.Channels(:));
        
        [calibrationSlope_, calibrationOffset_] = findSlopeOffset_(args.Channels(:), args.Gains(:), args.Resolution);
        args = rmfield(args, {'Channels', 'Gains'});
        
        cf = [4e6 48e6 750e3 24e6];
        div = [1 256];
            
        if isfield(args, 'SampleFrequency')
            desired = args.SampleFrequency;
            %find the best sample frequency configuration
            besterr = Inf;
            bestfreq = Inf;
            bestC = 0;
            bestD = 0;
            bestI = 65535;
            
            %I can probably do it better than a loop, huh? 750k clock
            %throws it off.
            for ClockFrequency = 0:3
                for DivideBy256 = 0:1
                    freq = cf(ClockFrequency+1)/div(DivideBy256+1);
                    ScanInterval = max(min(round(freq/desired), 65535), 1);
                    err = abs(desired - freq/ScanInterval);
                    if err < besterr
                        bestC = ClockFrequency;
                        bestD = DivideBy256;
                        bestI = ScanInterval;
                        besterr = err;
                        bestfreq = freq;
                    end
                end
            end
            packet.ClockFrequency = bestC;
            packet.DivideBy256 = bestD;
            packet.ScanInterval = bestI;
            r.SampleFrequency = bestfreq;
            r.NominalSampleFrequency = bestfreq;
            args = rmfield(args, 'SampleFrequency');
        end
        
        packet = namedargs(packet, args);
        r = roundtrip(STREAMCONFIG_COMMAND_, packet);
        r.SampleFrequency = cf(enumToNumber(packet.ClockFrequency, STREAM_CLOCK_FREQUENCY_)+1)/div(packet.DivideBy256+1)/packet.ScanInterval;
        
        fNominal_ = r.SampleFrequency;
        r = rmfield(r, 'reserved0');
        
        configured_ = strcmp(r.errorcode, 'NOERROR');
    end

%% StreamStart

% since we are apt to synchronize acquisition with things, this should be
% made to run fast.
    function r = streamStart(tBegin)
        if ~configured_
            error('LabJackUE9:notConfigured', 'Stream must be configured before starting');
        end
        
        pnet(a_, 'write', uint8([168 168]));
        
        if (nargin >= 1)
            tBegin_ = tBegin;
        else
            tBegin_ = 0;
        end
        
        %initialize our private buffers etc.
        lastserial_ = -1;

        incompleteSamples_ = [];
        incompleteChannels_ = [];
        incompleteData_ = [];

        warnDataLoss_ = 0;
        
        serialOffset_ = 0;
        
        if debug
            disp(strcat('>>> ', hexdump([168 168])));
        end
        r = pnet(a_, 'read', 4, 'uint8');
        if debug
            disp(strcat('<<< ', hexdump(r)));
        end
        if numel(r) < 4
            error('LabJackUE9:ReadTimeOut', 'packet read timeout');
        end
        if (r(2) ~= 169)
            error('LabJackUE9:mismatchedCommandNumbers', 'mismatched command response from streamStart');
        end
        s = sum(double(r([2 3 4])));
        s = s + floor(s/256);
        s = mod(s, 256);
        if (s ~= r(1))
            error('LabJackUE9:checksum','Packet read checksum failure');
        end
        
        r = struct('errorcode', enumToString(r(3), ERRORCODE_));
    end

%% StreamStop

    function [r, lostdata] = streamStop()
        %if ~configured_
        %    error('LabJackUE9:notConfigured', 'Stream must be configured before use');
        %end
        
        pnet(a_, 'write', uint8([176 176]));
        if debug
            disp(strcat('>>> ', hexdump([176 176])));
        end
        r = pnet(a_, 'read', 4, 'uint8');
        if debug
            disp(strcat('<<< ', hexdump(r)));
        end
        if numel(r) < 4
            error('LabJackUE9:ReadTimeOut', 'packet read timeout');
        end
        if (r(2) ~= 177)
            error('LabJackUE9:mismatchedCommandNumbers', 'mismatched command response from streamStop');
        end
        s = sum(double(r([2 3 4])));
        s = s + floor(s/256);
        s = mod(s, 256);
        if (s ~= r(1))
            error('LabJackUE9:checksum','Packet read checksum failure');
        end
        
        r = struct('errorcode', enumToString(r(3), ERRORCODE_));

        %report back on the operation of the stream
        if (warnDataLoss_)
            warning('LabJackUE9:lostData', 'Packet serial numbers indicated data loss during the scan');
            lostdata = 1;
        else
            lostdata = 0;
        end
        
        flush();
    end


%% StreamRead
    function [r] = streamRead()
        %function [r, seq, timestamps] = streamReadUncalibrated()
        %reads any stream data that has beeen received. The 'seq' and
        %'timestamps' are filled out with packets.
        
        %This is adapted from the routine I wrote for the PMD1208FS.m.
        %Hoever the labjack streams over a TCP connection so that
        %sequencing is guaranteed, which means this algorithm is a bit too
        %complicated (the PMD1208FS code had to deal with the report
        %buffer in PsychHID, which did not always report in order.)
        if ~configured_
            error('LabJackUE9:notConfigured', 'Stream must be configured before use');
        end

        latest = GetSecs();
        alldata = double(pnet(b_, 'read', 65504, 'uint8', 'noblock'));
        if debugstream && ~isempty(alldata)
            disp(strcat('+++ ', hexdump(alldata)));
        end
        
        if ~isempty(alldata)
            bytes = 32;
            samplesPer = 16;
            c = numel(calibrationSlope_);
            
            %each packet on Ethernet is 46 bytes long, aggregate them one per
            %column
            alldata = reshape(alldata, 46, []);

            %TODO check the checksum?
            
            err = max([0 alldata(12, :)]);
            
            %ignore data coming from errors
            alldata(:, logical(alldata(12, :))) = [];
                        
            %each packet also contains a 'reserved" timestamp
            timestamps = [1 256 65536 16777216] * alldata(7:10, :);
            
            %each packet contains an 18-bit serial number
            rawserials = alldata(11,:);
            serials = rawserials;

            %samples are uint16's
            data = reshape([1 256] * reshape(alldata(13:12+bytes, :), 2, []), samplesPer, []);
            
            %Deal with wraparound of the packet serial number. 
            
            %Since this is a TCP conn, sequencing will be guaranteed
            %(unlike with PsychHID's buffer, ha)
            %So dealing with packet number wraparound is now easier despite
            %only having 8 bits to work with.
            serials = serials + serialOffset_;
            adj = 256 * cumsum(diff([lastserial_ serials]) < 0);
            serials = serials + adj;
            serialOffset_ = serialOffset_ + adj(end);
            lastserial_ = serials(end);
            
            %Note that I use a double values that keep increasing to count
            %samples. The smallest positive integer not representable in a
            %double is 2^53 + 1; at 50000 samples/sec, it should take a few
            %thousand years before this runs into problems.
            
            %Now, the device just gives us a stream of data and expects us
            %to track whcih sample time and channel each number means.
            
            %Which channels and which (zero-based) channel index for each
            %bit of data?
            plus = (0:samplesPer-1)';
            plus = plus(:, ones(1,numel(serials)));
            %here 'channels' is the index into the scan list. 
            %FIXME rename?
            channels = serials(ones(samplesPer, 1), :)*mod(samplesPer, c);
            channels = mod(channels + plus, c);

            %which (zero-based) sample index for each bit of data?
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
            assembled(channels+1 + size(assembled, 1)*(samples - firstSample)) = data;
            
            samples = (firstSample:lastSample);
            times = samples / fNominal_;
            times = times + tBegin_;
            
            %we only return scans where we have all samples
            bf = ~isnan(assembled);
            good = all(bf, 1);
            bf(:,good) = 0; %bitfield shows incomplete samples
                 
            %these samples are good, forward them on
            data = assembled(:,good);
            [t, i] = sort(times(good));
            data = data(:,i);
            
            %deal with the incomplete samples (hold them over)
            [channelix, sampleix] = find(bf);
            incompleteSamples_ = sampleix + firstSample - 1;
            incompleteChannels_ = channelix - 1;
            incompleteData_ = assembled(bf);
            
            %FINALLY, apply the gain adjustments
            r.data = (data .* calibrationSlope_(:, ones(1, size(data, 2)))) ...
                   + calibrationOffset_(:, ones(1, size(data, 2)));
            r.rawdata = data;
            r.t = t;
            r.latest = latest;
            r.timestamps = timestamps;
            if err
                r.errorcode = enumToString(err, ERRORCODE_);
            else
                r.errorcode = '';
            end
        else
            %keeping zero dimension arrays dimensions consistent is
            %nice
            r.data = zeros(numel(calibrationSlope_), 0);
            r.errorcode = '';
            r.t = zeros(1, 0);
            r.latest = zeros(0, 1);
        end
    end

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
            error('LabJackUE9:errorReturned', 'error %d (%s) returned from Labjack', data(1), enumToString(data(1), ERRORCODE_));
        end
    end

%% ReadMem & LoadCalibration
    persistent READMEM_COMMAND_;
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

    %we have a wacky 64 bit fixed point data type for calibration...
    Z_ = struct('frac', uint32(0), 'int', int32(0));

    persistent CALIBRATION_FORMAT_;
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
        , 'Vsupply', struct...
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
        for i = 4:-1:0
            block(i+1) = readMem(i); %#ok, since growing downwards
            block(i+1).data = block(i+1).data(:)'; %#ok
        end
        
        c = frombytes([block.data], CALIBRATION_FORMAT_, 'littleendian', 1);
        c = rmfield(c, strcat('reserved', ('012345')'));
        c = unfix(c);
        calibration = c;
        updateSpecialCalibrations_();

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
                    %c = c;
            end
        end
    end

%% WriteMem
    persistent WRITEMEM_COMMAND_;
    WRITEMEM_COMMAND_ = struct...
        ( 'extended', 1 ...
        , 'commandNo', 40 ...
        , 'format', struct...
            ( 'blocknum', uint16(0) ...
            , 'data', zeros(128, 1, 'uint8') ...
            )...
        , 'response', struct...
           ( 'errorcode', ERRORCODE_ ...
           , 'reserved', uint8(0) ...
           ) ...
        );
    
    function response = writeMem(blocknum, data)
        if blocknum < 0 || blocknum > 7
            error('LabJackUE9:writeMem', 'invalid block number')
        end
        
        packet = WRITEMEM_COMMAND_.format;
        packet.blocknum = blocknum;
        packet.data = data;
        
        response = roundtrip(WRITEMEM_COMMAND_, packet);
    end

%% Communications (reading and writing packets)

    function response = roundtrip(command, data, varargin)
        remote = 1;
        extended = 0;
        
        if isfield(command, 'extended')
            extended = command.extended;
        end
        if isfield(command, 'remote')
            remote = command.remote;
        end

        sendPacket(command.commandNo, tobytes(command.format, data, LE_, varargin{:}), remote, extended);
        [commandNo, response] = readPacket();
        if ~isequal(commandNo, command.commandNo)
            error('LabJackUE9:mismatchedCommandNumbers', 'response command number %d from command %d', commandNo, command.commandNo);
        end
            
        response = frombytes(response, command.response, LE_, varargin{:});
    end
    
    function [release, params] = init(varargin)
        %It is preferred that you you use this with REQUIRE instead of open()
        %and close(). See the docs on 'require'.
        assertNotOpen_();
        
        initializer = joinResource...
            ( openPort(portA, @setA)...
            , @doFlush ...
            , openPort(portB, @setB)...
            , @setOpen ...
            , @getCal ...
            );

        [release, params] = initializer(namedargs(varargin{:}));
        
        function opener = openPort(port, setter)
            opener = @i;
            function [release, params] = i(params)
                handle = pnet('tcpconnect', host, port); %does port matter?
                if handle < 0
                    error('LabJackUE9:connection', 'Could not connect');
                end
                pnet(handle, 'setreadtimeout', readTimeout);
                pnet(handle, 'setwritetimeout', writeTimeout);
                setter(handle);
                
                release = @close;
                function close()
                    pnet(handle, 'close');
                    WaitSecs(0.1); %labjack seems to require this
                end
            end
        end
        
        function setA(a)
            a_ = a;
        end

        function setB(b)
            b_ = b;
        end
        
        function [release, params] = doFlush(params)
            flush();
            release = @flush;
        end
        
        function [release, params] = setOpen(params)
            open_ = 1;
            configured_ = 0;
            release = @close;
            function close()
                open_ = 0;
                configured_ = 0;
            end
        end
        
        function [release, params] = getCal(params)
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

    closer_ = @noop;
    function params = open(varargin)
        %Opens the device. Deprecated. Use INIT/REQUIRE in your programs.
        [closer_, params] = init(varargin);
    end

    function close()
        %Closes an open device, if is it open
        r = closer_;
        closer_ = @noop;
        r();
    end

    function assertOpen_()
        if ~open_
            error('LabJackUE9:DeviceNotOpen', 'Device must be opened. Use the initializer (see HELP REQUIRE.)');
        end
    end

    function assertNotOpen_()
        if open_
            error('LabJackUE9:DeviceOpen', 'Can''t do that while device is open');
        end
    end
    
    
    function flush()
        %just read (there's no explicit flush in pnet...)
        %assertOpen_();
        r = pnet(a_, 'read', 'uint8', 'noblock');
        if debug && numel(r)
            disp(strcat('xAx ', hexdump(r)));
        end

        %r = pnet(b_, 'read', 'uint8', 'noblock');
        %if debug && numel(r)
        %    disp(strcat('xBx ', hexdump(r)));
        %end
        pnet(a_, 'write', uint8([8 8]));
        resp = pnet(a_, 'read', 2, 'uint8');
        if ~isequal([8 8], resp)
            error('LabJackUE9:flushFailed', 'flush operation failed')
        end
        r = pnet(a_, 'read', 'uint8', 'noblock');
        if debug && numel(r)
            disp(strcat('xAx ', hexdump(r)));
        end
        %r = pnet(b_, 'read', 'uint8', 'noblock');
        %if debug && numel(r)
        %    disp(strcat('xBx ', hexdump(r)));
        %end
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
            error('LabJackUE9:checksum','Packet read checksum failure');
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

            if debug
                disp(strcat('<<< ', hexdump([in data xData])));
            end

            data = xData;
            commandNo = xCommandNo;
            
        else
            if debug
                disp(strcat('<<< ', hexdump([in data])));
            end
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
        %(double + int = int, f'rex.)
        
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

    function packet = lowlevel(packet, responsebytes)
        %FAST FAST FAST;
        %use this to send raw packets. The checksum and byte counts will be
        %computed for you, but that's it. Otherwise you have to provide the
        %entire packet INCLUDING spaces for the packet to go.
        assertOpen_();

        if bitand(packet(2), 120) == 120
            %extended checksum
            cksum = sum(packet(7:end));
            packet(5) = bitand(cksum, 255);
            packet(6) = bitshift(cksum, -8);
            packet(3) = numel(packet) / 2 - 3;
            cksum = sum(packet(2:6));
            cksum = bitand(cksum, 255) + bitshift(cksum, -8);
            packet(1) = bitand(cksum, 255) + bitshift(cksum, -8);
        else
            packet(2) = bitand(packet(2), 248) + numel(packet) / 2 - 1;
            cksum = sum(packet(2:min(16,end)));
            cksum = bitand(cksum, 255) + bitshift(cksum, -8);
            packet(1) = bitand(cksum, 255) + bitshift(cksum, -8);
        end
        
        pnet(a_, 'write', uint8(packet));
        if debug
            disp(strcat('>>> ', hexdump([packet])));
        end

        packet = pnet(a_, 'read', responsebytes, 'uint8');
        if debug
            disp(strcat('<<< ', hexdump([packet])));
        end
        
        assert(numel(packet) == responsebytes, 'response packet length failure');
        if numel(packet) < responsebytes
            error('LabJackUE9:ReadTimeOut', 'packet read timeout');
        end

        %check checksums
        if bitand(packet(2), 120) == 120
            cksum = sum(packet(7:end));
            assert(packet(5) == bitand(cksum, 255), 'Extended checksum failure');
            assert(packet(6) == bitshift(cksum, -8), 'Extended checksum failure');
            assert(packet(3) == numel(packet) / 2 - 3, 'Response packet length failure');
            cksum = sum(packet(2:6));
            cksum = bitand(cksum, 255) + bitshift(cksum, -8);
            assert(packet(1) == bitand(cksum, 255) + bitshift(cksum, -8), 'Checksum failure');
        else
            assert(bitand(packet(2), 7) == numel(packet) / 2 - 1, 'Response packet length failure');
            cksum = sum(packet(2:min(16,end)));
            cksum = bitand(cksum, 255) + bitshift(cksum, -8);
            assert(packet(1) == bitand(cksum, 255) + bitshift(cksum, -8), 'checksum failure');
        end
    end
end