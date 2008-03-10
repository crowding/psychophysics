function y = pmwelch(x,nfft,window,noverlap)
%PSD = PMWELCH(X,NFFT,WINDOW,NOVERLAP)
%
%   Example: x = auread('soundfile.au');
%            plot(pmwelch(x,65536,hamming(65536),32768))
%
%   See also PWELCH.   

x = x(:);
window = window(:);
nwin = length(window);
nx= length(x);
if nx < nwin
   x(nwin) = 0; % pad with zeros!
   nx = nwin;
end
nseg = fix((nx-noverlap)/(nwin-noverlap));

w = pmjob;
w.expr = 'y=abs(fft(x.*window,nfft)).^2;';
w.argin = {'x'};
w.argout = {'y'};
w.datain = {'GETBLOC(1)'};
w.dataout = {'SETBLOC(1)'};
w.comarg = {'nfft' 'window'};
w.comdata = {nfft window};

xover = zeros(nfft,nseg);
ind = 1:nwin;
for n = 1:nseg
   xover(:,n) = x(ind);
   ind = ind + (nwin - noverlap);
end

inds = createinds(xover,[nfft 1]);
w.blocks = pmblock('src',inds,'dst',inds);

w.input{1} = xover;

clear xover
err = dispatch(w);

y = sum(w.output{1},2);
y = y/(2*pi*nseg*norm(window)^2); % normalise










