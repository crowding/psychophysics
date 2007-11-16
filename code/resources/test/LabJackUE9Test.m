function this = LabJackUE9Test(varargin)
    %This test suite exercises the LabJack UE9 data acquisition device
    %using my Ethernet library.

    debug = 0; %pass debug = 1 to see the bytes go by.
    host = '100.1.1.3'; %fill in your host here...

    persistent init__;
    this = inherit(TestCase(), autoobject(varargin{:}));

    lj = LabJackUE9('debug', debug, 'host', host);
    
    function initializer = init()
        %For semi-independent testing, must open/close the labjack for every test and reset pnet
        initializer = joinResource(@resetPnet, lj.init());
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
        
        %output fromm DAC0 to AIN0 and DAC1 to FIO4, and check values
        r = lj.feedback...
            ( 'DAC0Update', 1, 'DAC0Enabled', 1, 'DAC0Voltage', 4.0 ...
            , 'DAC1Update', 1, 'DAC1Enabled', 1, 'DAC1Voltage', 4.0 ...
            , 'FIOMask', [0 0 0 1 1 0 0 0], 'FIODir', [0 0 0 1 0 0 0 0], 'FIOState', [0 0 0 0 0 0 0 0]);
        
        %unset outputs
        r2 = lj.feedback...
            ( 'DAC0Update', 1, 'DAC0Enabled', 0 ...
            , 'DAC1Update', 1, 'DAC1Enabled', 1 ...
            , 'FIOMask', [1 1 1 1 1 1 1 1], 'FIODir', [0 0 0 0 0 0 0 0]);
        
        assertIsEqual(1, r.FIODir(4));
        assertIsEqual(0, r.FIODir(5));
        assertIsEqual(1, r.FIOState(5));
        assertIsEqual(0, r.FIOState(4));
        assertClose(4.0, r.AINValue(1));

        assert(all(r2.FIODir == 0));
    end

    function testFeedbackAlt()
        %this should read everything...
        r = lj.feedbackAlt();
        assert(~isfield(r, 'TimerA'));
        
        %output fromm DAC0 to AIN0 and check values
        r = lj.feedbackAlt...
            ( 'DAC0Update', 1, 'DAC0Enabled', 1, 'DAC0Voltage', 3.0 ...
            , 'DAC1Update', 1, 'DAC1Enabled', 1, 'DAC1Voltage', 4.0 ...
            , 'FIOMask', [1 0 1 0 1 0 0 0], 'FIODir', [1 0 0 0 0 0 0 0], 'FIOState', [0 0 0 0 0 0 0 0]...
            , 'AINChannelNumber', [ 132 0 133 14 132 0 133 14 132 0 133 14 132 0 133 14]...
            , 'AINGain', {'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1', 'x1'}...
            , 'AINMask', [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]...
            , 'Resolution', 16 ...
            );
       
        assertIsEqual(1, r.FIODir(1));
        assertIsEqual(0, r.FIODir(2));
        assertIsEqual(0, r.FIOState(1));
        assertIsEqual(0, r.FIOState(3));
        assertIsEqual(1, r.FIOState(5));
        assertClose([5 3.0 290 2.43 5 3.0 290 2.43 5 3.0 290 2.43 5 3.0 290 2.43]', r.AINValue);
        
        %unset outputs
        r = lj.feedbackAlt('DAC0Update', 1, 'DAC0Enabled', 0 ...
            , 'FIOMask', [1 1 1 1 1 1 1 1], 'FIODir', [0 0 0 0 0 0 0 0]);
        
        assert(all(r.FIODir == 0));
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
        assertIsEqual(r.dir, 0);
        
        r = lj.bitOut(1, 0, 0);
        assertIsEqual(r.channel, 'FIO1');
        assertIsEqual(r.dir, 0);
        
        r = lj.bitOut('FIO0', 1, 0);
        assertIsEqual(r.channel, 'FIO0');
        assertIsEqual(r.dir, 1);
        assertIsEqual(r.state, 0);        
    end

    function testBitIO()
        %round trip test: assume FIO0 is connected to FIO2.
        %set both to input
        lj.bitOut(0, 0, 0);
        lj.bitOut(2, 0, 0);

        %read state
        r = lj.bitIn(0);
        assertIsEqual(r.dir, 0);
        
        %set 0 to output a 0
        lj.bitOut(0, 1, 0);
        r = lj.bitIn(0);
        assertIsEqual(r.dir, 1);
        assertIsEqual(r.state, 0);

        %set channel to to output a 1
        r = lj.bitOut(0, 1, 1);
        r = lj.bitIn(0);
        assertIsEqual(r.state, 1);

        %check connection to channel 1
        r = lj.bitIn(2);
        assertIsEqual(r.dir, 0);
        assertIsEqual(r.state, 1);
        
        lj.bitOut(0, 1, 0);
        r = lj.bitIn(2);
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
        %this requires connecting DAC0 to AIN0...
        
        for v = 0.1:0.1:4.9
            lj.voltageOut(0, v);
            a = lj.analogIn(0, 0);
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
        %assumes that FIO0 is connected to FIO2;
        r = lj.portOut(0, [1 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0]);
        r = lj.portIn(0);
        assertIsEqual(0, r.state(1));
        assertIsEqual(0, r.state(3));
        r = lj.portOut(0, [1 0 0 0 0 0 0 0], [1 0 0 0 0 0 0 0]);        
        r = lj.portIn(0);
        assertIsEqual(1, r.state(1));
        assertIsEqual(1, r.state(3));
        r = lj.portOut(0, [0 0 1 0 0 0 0 0], [1 0 0 0 0 0 0 0]);        
        r = lj.portIn(0);
        assertIsEqual(0, r.state(1));
        assertIsEqual(0, r.state(3));
    end

%% TimerCounter
    function testTimerCounter()
        %For this test FIO0 needs to connect to FIO2 and FIO1 to FIO3.
        
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
            , 'Timer0.mode', 'FirmwareCounter' ...
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
            ( 'Channels', [0 0]...
            , 'Gains', [0 0]...
            , 'SampleFrequency', 1000 ...
            );
        
        lj.voltageOut('DAC0', 2.5);
        
        r = lj.streamStart();
        assertIsEqual(r.errorcode, 'NOERROR');
        
        try
            WaitSecs(0.1);

            data = lj.streamRead();
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