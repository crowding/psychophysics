function af = avi(this,name,cal)
    if ~exist('cal', 'var')
        cal = Calibration();
    end
    
    m = movie(this,cal);
   
    %convert each frame to a movie frame
    
    af = avifile(name, 'fps', 1/cal.interval, 'Colormap', gray(256));

    for i = 1:size(m, 3)
        addframe(af, m(:,:,[i i i])/2 + 1);
    end
    
    af = close(af);
end