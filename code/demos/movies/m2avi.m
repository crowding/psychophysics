function af = m2avi(m, name, cal)
    if ~exist('cal', 'var')
        cal = Calibration();
    end
    
    %convert each frame to a movie frame
    af = avifile(name, 'fps', 1/cal.interval, 'Colormap', gray(256));

    for i = 1:size(m, 3)
        %mov(i) = im2frame(m(:,:,[i i i])/2 + 0.5, gray(256));
        af = addframe(af, m(:,:,[i i i])/2 + 0.5);
    end
    %movie2avi(mov, name, 'FPS', 1/cal.interval);
    af = close(af);
end