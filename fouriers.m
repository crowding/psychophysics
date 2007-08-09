function fouriers
    figure(1);
    
    showfouriers('glolo60.mov', 128, [], [], 'glolo60.mov', 384, [], []);
end


function showfouriers(movie1, x1, y1, t1, movie2, x2, y2, t2);
    sfourier(movie1, x1, y1, t1, 1, 3);
    sfourier(movie2, x2, y2, t2, 2, 4);

    function sfourier(movie1, x1, y1, t1, sp1, sp2);
        [z, x, y, t] = importQT(movie1, x1, y1, t1);
        z = mean(z, 3);
        z = squeeze(z)';
        subplot(2, 2, sp1);
        imagesc(x, t, z);
        colormap gray(256);
        subplot(2, 2, sp2);
        zf = fft2(z);
        zf(1,:) = 0;
        zf(:,1) = 0;
        imagesc(log(fftshift(real(zf .* conj(zf))))); axis off;
        [l, r] = menergy(z);
        title(sprintf('%02g %% left, %02g %% right',  l * 100, r * 100));
    end
end