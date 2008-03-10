function [y] = welch(x,nfft,window,noverlap)

x = x(:);
window = window(:);
nwin = length(window);
nx= length(x);
if nx < nwin
   x(nwin) = 0; % pad with zeros!
   nx = nwin;
end
nseg = fix((nx-noverlap)/(nwin-noverlap));

% calculate the power spectral density
y = zeros(nfft,1);
ind = 1:nwin;
for n = 1:nseg
   xw = window.*x(ind);
   ind = ind + (nwin - noverlap);
   y = y + abs(fft(xw,nfft)).^2;
end
y=y/(2*pi*nseg*norm(window)^2); % normalise
