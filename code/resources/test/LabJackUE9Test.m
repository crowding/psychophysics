function this = LabJackUE9Test(varargin)
    %This test suite exercises the LabJack UE9 data acquisition device
    %using my Ethernet library.
    %
    %In order to run the tests, you need to make the following connections
    %on the expansion boards:
    %
    % DAC0 <-> AIN7
    % DAC1 <-> MIO0
    % MIO1 <-> MIO2
    % CIO0 <-> CIO1
    % CIO2 <-> CIO3
    %
    % Nothing special about these--just pins I'm not using in my
    % application.
    %
    % There are also some 'special' tests, which either require different
    % connections or are destructive (erasing bootup params, memory, etc.)
    %
    % To run a special test, do
    %
    % runTests(LabJackUE9Test(), 'specialTestName');

    debug = 0; %pass debug = 1 to see the bytes go by.
    host = '100.1.1.3'; %fill in your host here...

    persistent init__;
    this = inherit(TestCase(), autoobject(varargin{:}));

    lj = LabJackUE9('debug', debug, 'host', host);
    
    function initializer = init()
        %For semi-independent testing, must open/close the labjack for every test and reset pnet
        initializer = joinResource(@resetPnet, lj.init);
    end

    function [release, params] = resetPnet(params)
        clear('pnet'); %closes all
        evalc('pnet closeall'); %reloads; evalc is to suppress the startup message
        release = @noop;
    end

%% CommConfig
    function testReadCommConfig()
        c = lj.commConfig();
        assertIsEqual(9, c.ProductID);
        assertIsEqual(lj.getPortA(), c.PortA);
        
        %the IP address (subnet, gateway) should be in normal order as
        %reported by pnet. This test won't work if you have the thing
        %behind a NAT...
        assertIsEqual(c.IPAddress, lj.getIPAddress())
    end

    function specialTestWriteCommConfig()
        %minimal test, just set the thing to what it must already be
        %and check the write mask. Flash is not good for many write
        %cycles so this is a special test.
        pa = lj.getPortA();
        r = lj.commConfig('PortA', lj.getPortA());
        assert(r.writeMask.PortA);
        assertIsEqual(pa, r.PortA);
    end

    function testFlush()
        lj.flush();
    end

%% DiscoverUDP
    function specialTestDiscover()
        %We need a bone stock unopened LJ object for the next test.
        l = LabJackUE9();
        l.setHost([]);
        l.setPortA([]);
        l.setPortB([]);
        
        %use the 'discover' UDP command to get a list of devices.
        d = l.discover();
        %devices should be a struct and should have an IP address...
        assertIsEqual(size(d(1).IPAddress), [1 4]);
        
        %'host' should reflect the IP address now.
        assertIsEqual(l.getHost(), sprintf('%d.%d.%d.%d', d(1).IPAddress));
        assertIsEqual(l.getPortA(), d(1).PortA);
        assertIsEqual(l.getPortB(), d(1).PortB);
    end

%% ControlConfig
    function testReadControlConfig()
        %this is basic...
        r = lj.readControlConfig();
        assert(isfield(r, 'FIODir'));
    end

    function specialTestWriteControlConfig()
        r = lj.writeControlConfig('MIOState', [1 1 1], 'PowerLevel', 1);
        assertIsEqual([1 1 1], r.MIOState);
    end

%% Feedback
    function testFeedback()
        %this should read everything...
        r = lj.feedback();
        assert(isfield(r, 'TimerA'));
        
        %output fromm DAC0 to AIN7, DAC1 to MIO0, MIO1 to MIO2 and check values
        r = lj.feedback...
            ( 'DAC0Update', 1, 'DAC0Enabled', 1, 'DAC0Voltage', 4.0 ...
            , 'DAC1Update', 1, 'DAC1Enabled', 1, 'DAC1Voltage', 4.0 ...
            , 'MIOMask', [1 1 1], 'MIODir', [0 1 0], 'MIOState', [0 1 0]);
        
        %unset outputs
        r2 = lj.feedback...
            ( 'DAC0Update', 1, 'DAC0Enabled', 0 ...
            , 'DAC1Update', 1, 'DAC1Enabled', 1 ...
            , 'MIOMask', [1 1 1], 'MIODir', [0 0 0]);
        
        assertIsEqual(1, r.MIODir(2));
        assertIsEqual(0, r.MIODir(1));
        assertIsEqual(1, r.MIOState(1));
        assertIsEqual(1, r.MIOState(3));
        assertClose(4.0, r.AINValue(14));

        assert(all(r2.MIODir == 0));
    end

    function testFeedbackAlt()
        %this should read everything...
        r = lj.feedbackAlt();
        assert(~isfield(r, 'TimerA'));
        
        %output fromm DAC0 to AIN0 and check values
        r = lj.feedbackAlt...
            ( 'DAC0Update', 1, 'DAC0Enabled', 1, 'DAC0Voltage', 3.0 ...
            , 'DAC1Update', 1, 'DAC1Enabled', 1, 'DAC1Voltage', 4.0 ...
            , 'MIOMask', [1 1 1], 'MIODir', [0 1 0], 'MIOState', [0 1 0]...
            , 'AINChannelNumber', [ 132 13 133 14 132 13 133 14 132 13 133 14 132 13 133 14]...
            , 'AINGain', {'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1'}...
            , 'AINMask', [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]...
            , 'Resolution', 16 ...
            );
       
        %unset outputs
        r2 = lj.feedbackAlt('DAC0Update', 1, 'DAC0Enabled', 0 ...
                      , 'DAC1Update', 1, 'DAC1Enabled', 1 ...
                      , 'MIOMask', [1 1 1], 'MIODir', [0 0 0]);
        
        assertIsEqual(1, r.MIODir(2));
        assertIsEqual(0, r.MIODir(1));
        assertIsEqual(1, r.MIOState(1));
        assertIsEqual(1, r.MIOState(3));
        assertClose([5 3.0 290 2.43 5 3.0 290 2.43 5 3.0 290 2.43 5 3.0 290 2.43]', r.AINValue);
        
        assert(all(r2.MIODir == 0));
    end

%% SingleIO
    function testBitIn()
        %set both to input
        r = lj.bitIn(0);
        assertIsEqual(r.channel, 'FIO0');
        r = lj.bitIn('FIO1');
        assertIsEqual(r.channel, 'FIO1');
    end

    function testBitOut()
        %set both to input
        r = lj.bitOut(0, 0, 0);
        assertIsEqual(r.channel, 'FIO0');
        assertIsEqual(r.dir, 'in');
        
        r = lj.bitOut(1, 0, 0);
        assertIsEqual(r.channel, 'FIO1');
        assertIsEqual(r.dir, 'in');
        
        r = lj.bitOut('FIO0', 1, 0);
        assertIsEqual(r.channel, 'FIO0');
        assertIsEqual(r.dir, 'out');
        assertIsEqual(r.state, 0);        
    end

    function testBitIO()
        %round trip test: assume CIO0 is connected to MIO2.
        %set both to input
        lj.bitOut('CIO0', 'in', 0);
        lj.bitOut('CIO2', 'in', 0);

        %read state
        r = lj.bitIn('CIO0');
        assertIsEqual(r.dir, 'in');
        
        %set 0 to output a 0
        lj.bitOut('CIO0', 1, 0);
        r = lj.bitIn('CIO0');
        assertIsEqual(r.dir, 'out');
        assertIsEqual(r.state, 0);

        %set channel to to output a 1
        r = lj.bitOut('CIO0', 1, 1);
        r = lj.bitIn('CIO0');
        assertIsEqual(r.state, 1);

        %check connection to channel 1
        r = lj.bitIn('CIO2');
        assertIsEqual(r.dir, 'in');
        assertIsEqual(r.state, 1);
        
        lj.bitOut('CIO0', 1, 0);
        r = lj.bitIn('CIO2');
        assertIsEqual(r.state, 0);
    end


    function testAnalogIn()
        %read the analog port and convert to voltage...
        %at several gain levels, and bipolar. They should line up
        %more or less.
        
        %vref at different gains
        a = lj.analogIn(14);
        assertIsEqual('Vref', a.channel);
        assertClose(8059632, a.AIN);
        assertClose(2.43, a.value);
        a = lj.analogIn('Vref', 1);
        assertClose(16119264, a.AIN);
        assertClose(2.43, a.value);
        a = lj.analogIn(14, 8);
        assertClose(12418424, a.AIN);
        assertClose(2.43, a.value);
        a = lj.analogIn(14, 8);
        assertClose(12418424, a.AIN);
        assertClose(2.43, a.value);
        
        %check low resolution
        a = lj.analogIn(14, 0, 12);
        assertClose(8059632, a.AIN);
        assertClose(2.43, a.value);
        assertEquals(0, bitand(a.AIN, sum(bitset(0, 1:12))));
        
        %check temp, gnd, Vs
        a = lj.analogIn(133, 0);
        assertClose(290, a.value, 0, 15);

        a = lj.analogIn(15, 0);
        assertClose(0, a.value, 0, 0.05);
        
        a = lj.analogIn(132, 0);
        assertClose(5, a.value);
    end

    function testAnalogOut()
        %write the analog port with a voltage...
        lj.voltageOut(0, 0);
    end

    function testAnalogIO()
        %this requires connecting DAC0 to AIN13...
        
        for v = 0.1:0.1:4.9
            lj.voltageOut(0, v);
            a = lj.analogIn(13, 0);
            assertClose(v, a.value, 0.05, 0.05);
        end
    end

    function testPortIn
        r = lj.portIn(0);
        assertIsEqual(r.port, 'FIO');
        r = lj.portIn(1);
        assertIsEqual(r.port, 'EIO');
    end

    function testPortOut
        r = lj.portOut(0, [0 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0]);
        assertIsEqual(r.port, 'FIO');
        assertIsEqual(r.dir, [0 0 0 0 0 0 0 0]);
        r = lj.portOut(0, [1 0 0 0 0 0 0 0], [1 0 0 0 0 0 0 0]);
        assertIsEqual(r.port, 'FIO');
        assertIsEqual(r.dir, [1 0 0 0 0 0 0 0]); 
    end

    function testPortIO
        %assumes that CIO0 is connected to CIO2;
        r = lj.portOut(2, [1 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0]);
        r = lj.portIn('CIO');
        assertIsEqual(0, r.state(1));
        assertIsEqual(0, r.state(3));
        r = lj.portOut('CIO', [1 0 0 0 0 0 0 0], [1 0 0 0 0 0 0 0]);        
        r = lj.portIn(2);
        assertIsEqual(1, r.state(1));
        assertIsEqual(1, r.state(3));
        r = lj.portOut('CIO', [0 0 1 0 0 0 0 0], [1 0 0 0 0 0 0 0]);        
        r = lj.portIn('CIO');
        assertIsEqual(0, r.state(1));
        assertIsEqual(0, r.state(3));
    end

%% TimerCounter
    function testTimerCounter()
        %Without running any tests, the best we can do is reading the
        %system timer/counter.
        
        %Will output on FIO1 and FIO2.
        %first, the bare command reads the timer-counter configuration.
        r = lj.timerCounter();

        assert(isfield(r, 'Timer0'));
        assert(isfield(r, 'Counter1'));
        
        %make them count up at 100 Hz
        r = lj.timerCounter...
            ( 'NumTimers', 2 ...
            , 'Timer0.Mode', 'SystemTimerLow' ...
            , 'Timer1.Mode', 'SystemTimerHigh' ...
            );
        
        value1 = double(r.Timer0) + 65536*double(r.Timer1);
        
        WaitSecs(1);
        
        r2 = lj.timerCounter();
        value2 = double(r2.Timer0) + 65536*double(r2.Timer1);
        
        lj.timerCounter('NumTimers', 0);
        
        assertClose(value2-value1, 750000);
    end
    
    function specialTestTimerStop()
        %For this test FIO2, 1, 0 all need to be ganged together.
        %To run this test, 
        %
        %>> runTests(LabJackUE9Test(), 'SpecialTestTimerStop')
        
        %This clarifies some behavior on timer stopping.

        lj.timerCounter('NumTimers', 0);
        
        lj.portOut('FIO', [1 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0]); %ouput low to begin
        
        r = lj.timerCounter...
            ( 'NumTimers', 2 ...
            , 'Counter0Enabled', 1 ...
            , 'UpdateReset.Counter0', 1 ...
            , 'TimerClockBase', 'K750' ...
            , 'TimerClockDivisor', 75 ...
            , 'Timer0.Mode', 'Frequency' ...
            , 'Timer0.Value', 50 ...           %1Khz
            , 'Timer1.Mode', 'TimerStop' ...
            , 'Timer1.Value', 12 ...         %waits for 120 
            );
        
        WaitSecs(0.2);
        r2 = lj.timerCounter('Timer1.Value', 20, 'Timer0.Value', 50)
        WaitSecs(0.3);
        r3 = lj.timerCounter()
        r4 = lj.timerCounter('NumTimers', 0);
        
        assertIsEqual(r2.Counter0, 11);
    end

    function secialTestTimerCounter()
        %older test, needs FIO2<->FIO0 and FIO3<->FIO2
        %For this test FIO0 needs to connect to FIO2 and FIO1 to FIO3.
        %This is therefore a special test, since I need all the timer lines
        %in my rig.
                
        %first, the bare command reads the timer-counter configuration.
        r = lj.timerCounter();

        assert(isfield(r, 'Timer0'));
        assert(isfield(r, 'Counter1'));
        
        %configure the timers and counters...
        %FIO2 is connected to FIO0 and FIO3 to FIO2.
        
        %Configure FIO3 and 2 to output high 
        lj.portOut('FIO', [0 0 1 1 0 0 0 0], [0 0 1 1 0 0 0 0]);
        
        %enable and reset one timer; will live on FIO0.
        %enable and reset one Counter; will live on FIO1.
        r = lj.timerCounter...
            ( 'NumTimers', 1 ...
            , 'Counter0Enabled', 1 ...
            , 'UpdateReset.Counter0', 1 ...
            , 'Timer0.Mode', 'FirmwareCounter' ...
            , 'Timer0.value', 0 ...
            );
        
        %Now toggle FIO2 two times and FIO3 three times.
        for i = 1:2
            lj.bitOut('FIO2', 1, 0);
            lj.bitOut('FIO2', 1, 1);
        end
        
        for i = 1:3
            lj.bitOut('FIO3', 1, 0);
            lj.bitOut('FIO3', 1, 1);
        end

        %now read the timers
        r = lj.timerCounter();
        
        %and disable them (apparently it won't read timers if you are
        %disabling them
        lj.timerCounter('NumTimers', 0, 'Counter0Enabled', 0, 'Counter1Enabled', 0);
        %and release the outputs
        lj.portOut('FIO', 0, 0);
        
        %check that we got the right counts
        assertIsEqual(2, r.Timer0);
        assertIsEqual(3, r.Counter0);
    end

%% StreamConfig

    function testStreamConfig()
        %configure a stream...
         r = lj.streamConfig...
             ( 'Channels', [0 1 2 3]...
             , 'Gains', [3 2 1 0]...
             , 'ClockFrequency', 'k750' ...
             , 'DivideBy256', 0 ...
             , 'ScanInterval', 750 ...
             );
         
         assertIsEqual('NOERROR', r.errorcode);
         assertIsEqual(1000, r.SampleFrequency);
         
         %also configure with a chosen frequency
         r = lj.streamConfig...
             ( 'Channels', [0 1]...
             , 'Gains', [0 0]...
             , 'SampleFrequency', 1000 ...
             , 'TriggerEnabled', 1 ...
             , 'PulseEnabled', 0 ...
             );
         assertIsEqual('NOERROR', r.errorcode);
         assertIsEqual(1000, r.SampleFrequency);
    end

%% StreamStart & StreamStop

    function testStreamStartStop()
        r = lj.streamConfig...
            ( 'Channels', [0 1]...
            , 'Gains', [0 0]...
            , 'SampleFrequency', 1000 ...
            );
            
        r = lj.streamStart();
        assertIsEqual(r.errorcode, 'NOERROR');
        r = lj.streamStop();
        assertIsEqual(r.errorcode, 'NOERROR');
    end

%% StreamRead
    function testStreamRead()
        %In this test DAC0 should be connected to AIN0.
        
        lj.streamConfig...
            ( 'Channels', {'AIN13', 'AIN13'}...
            , 'Gains', [0 0]...
            , 'SampleFrequency', 1000 ...
            );
        
        lj.voltageOut('DAC0', 2.5);
        
        r = lj.streamStart();
        assertIsEqual(r.errorcode, 'NOERROR');
        
        try
            WaitSecs(0.1);

            data = lj.streamRead(); %you can call streamRead as often as you want here...
        catch
            lj.streamStop();
            rethrow(lasterror);
        end
        
        lj.streamStop();
        
        assert(~isempty(data.data));
        assert(~isempty(data.t));
        
        assertIsEqual(size(data.data, 1), 2);
        assertClose(size(data.data, 2), 96);
        
        assertClose(data.data, 2.5);

    end

%% ReadMem
    function testReadMem()
        %check for the calibration in block 0
        response = lj.readMem(0);
        assertEquals(numel(response.data), 128);
        assertIsEqual(response.blocknum, 0);
        response = lj.readMem(1);
        assertIsEqual(response.blocknum, 1);
        response = lj.readMem(15);
        assertIsEqual(response.blocknum, 15);
        try
            lj.readmem(16)
            fail('should throw');
        catch
        end
    end


    function testLoadCalibration()
        c = lj.loadCalibration();
        assertEquals(numel(c.ADCUnipolar), [4]);
        %check a couple values close enough to nominal
        assert(abs(log(c.ADCUnipolar(2).slope / 3.8736E-05)) < 0.1);
        assert(abs(log(c.ADCUnipolar(2).offset / -1.2E-02)) < 0.1);
        assert(abs(log(c.DAC(1).slope / 8.429E02)) < 0.1);
        assert(abs(log(c.ADCUnipolar(2).offset / -1.2E-02)) < 0.1);
    end


end