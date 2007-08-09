function [right, left] = menergy(z)
    zf = fft2(z);
    
    [r, c] = size(zf);
    energy = real(zf .* conj(zf));
    right = sum(sum(energy(2:floor((r+1)/2), 2:floor((c+1)/2)) + energy(ceil((r+1)/2)+1:end, ceil((c+1)/2)+1:end)));
    left  = sum(sum(energy(2:floor((r+1)/2), ceil((c+1)/2)+1:end) + energy(ceil((r+1)/2)+1:end, 2:floor((c+1)/2))));
        
    total = right + left;
    right = right / total;
    left = left / total;
end