function this = LabJackUE9Test(varargin)
    
    this = inherit(TestCase(), autoobject(varargin{:}));

    lj = LabJackUE9();
    
    function initializer = init()
        %must open/close the labjack for every test and reset pnet
        initializer = joinResource(@resetPnet, lj.init());
    end

    function [release, params] = resetPnet(params)
        clear('pnet');
        evalc('pnet closeall');
        release = @noop;
    end

    function testGetCommConfig()
        c = lj.readCommConfig();
        assertIsEqual(9, c.ProductID);
        assertIsEqual(lj.getPortA(), c.PortA);
    end

    function specialTestSetCommConfig()
        %minimal test, just set the thing to what it must already be
        %and check the write mask. Flash is not good for many write
        %cycles so this is a special test.
        pa = lj.getPortA();
        r = lj.writeCommConfig('PortA', lj.getPortA());
        assert(r.writeMask.PortA);
        assertIsEqual(pa, r.PortA);
    end

    function testFlushBuffer()
        lj.flushBuffer();
        %Dunno how to check results...
    end

    function testBitIn()
        %set both to input
        r = lj.bitIn(0);
        assertIsEqual(r.channel, 0);
        r = lj.bitIn(1);
        assertIsEqual(r.channel, 1);
    end

    function testBitOut()
        %set both to input
        r = lj.bitOut(0, 0, 0);
        assertIsEqual(r.channel, 0);
        assertIsEqual(r.dir, 0);
        
        r = lj.bitOut(1, 0, 0);
        assertIsEqual(r.channel, 1);
        assertIsEqual(r.dir, 0);
        
        r = lj.bitOut(0, 1, 0);
        assertIsEqual(r.channel, 0);
        assertIsEqual(r.dir, 1);
        assertIsEqual(r.state, 0);        
    end

    function testBitIO()
        %round trip test: assume FIO0 is connected to FIO1.
        %set both to input
        lj.bitOut(0, 0, 0);
        lj.bitOut(1, 0, 0);

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
        r = lj.bitIn(1);
        assertIsEqual(r.dir, 0);
        assertIsEqual(r.state, 1);
        
        lj.bitOut(0, 1, 0);
        r = lj.bitIn(1);
        assertIsEqual(r.state, 0);
    end


    function testAnalogIn()
        %read the analog port and convert to voltage...
        %at several gain levels, and bipolar. They should line up
        %more or less.
        
        %vref at different gains
        a = lj.analogIn(14);
        assertIsEqual(14, a.channel);
        assertClose(8059632, a.AIN);
        assertClose(2.43, a.value);
        a = lj.analogIn(14, 1);
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
        lj.analogOut(0, 0);
    end

    function testAnalogIO()
        %this requires connecting DAC0 to AIN0...
        
        for v = 0.1:0.1:4.9
            lj.analogOut(0, v);
            a = lj.analogIn(0, 0);
            assertClose(v, a.value, 0.05, 0.05);
        end
    end

    function testPortIn
        r = lj.portIn(0);
        assertIsEqual(r.channel, 0);
        r = lj.portIn(1);
        assertIsEqual(r.channel, 1);
    end

    function testPortOut
        r = lj.portOut(0, [0 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0]);
        assertIsEqual(r.channel, 0);
        assertIsEqual(r.dir, [0 0 0 0 0 0 0 0]);
        r = lj.portOut(0, [1 0 0 0 0 0 0 0], [1 0 0 0 0 0 0 0]);
        assertIsEqual(r.channel, 0);
        assertIsEqual(r.dir, [1 0 0 0 0 0 0 0]); 
    end

    function testPortIO
        %assumes that FIO0 is connected to FIO1;
        r = lj.portOut(0, [1 0 0 0 0 0 0 0], [0 0 0 0 0 0 0 0]);
        r = lj.portIn(0);
        assertIsEqual(0, r.state(1));
        assertIsEqual(0, r.state(2));
        r = lj.portOut(0, [1 0 0 0 0 0 0 0], [1 0 0 0 0 0 0 0]);        
        r = lj.portIn(0);
        assertIsEqual(1, r.state(1));
        assertIsEqual(1, r.state(2));
        r = lj.portOut(0, [0 1 0 0 0 0 0 0], [1 0 0 0 0 0 0 0]);        
        r = lj.portIn(0);
        assertIsEqual(0, r.state(1));
        assertIsEqual(0, r.state(2));
    end


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