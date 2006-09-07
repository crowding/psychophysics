function g = get_gamma(this)
    if ~this.calibrated
        warning('Calibration:uncalibrated', 'screen is not calibrated!');
    end
    
    g = this.gamma;
