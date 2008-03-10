% imported: no_lines, fs.

% initialisation file for probe

f0=3.5e6;                %  Transducer center frequency [Hz]
%fs=100e6;                %  Sampling frequency [Hz]
c=1540;                  %  Speed of sound [m/s]
lambda=c/f0;             %  Wavelength [m]
width=lambda;            %  Width of element
element_height=5/1000;   %  Height of element [m]
kerf=0.05/1000;          %  Kerf [m]
focus=[0 0 70]/1000;     %  Fixed focal point [m]
N_elements=192;          %  Number of physical elements
N_active=64;             %  Number of active elements 

% Do not use triangles

set_field('use_triangles',0);

%  Set the sampling frequency

set_sampling(fs);

%  Generate aperture for emission

xmit_aperture = xdc_linear_array (N_elements, width, element_height, kerf, 1, 10,focus);

%  Set the impulse response and excitation of the xmit aperture

impulse_response=sin(2*pi*f0*(0:1/fs:2/f0));
impulse_response=impulse_response.*hanning(max(size(impulse_response)))';
xdc_impulse (xmit_aperture, impulse_response);

excitation=sin(2*pi*f0*(0:1/fs:2/f0));
xdc_excitation (xmit_aperture, excitation);

%  Generate aperture for reception

receive_aperture = xdc_linear_array (N_elements, width, element_height, kerf, 1, 10,focus);

%  Set the impulse response for the receive aperture

xdc_impulse (receive_aperture, impulse_response);

%  Set the different focal zones for reception

focal_rec=[30:20:200]'/1000;
focus_times_rec=(focal_rec-10/1000)/1540;
focal_xmit=60/1000;          %  Transmit focus
focus_times_xmit = 0;

Nft = length(focal_xmit);
Nfr = length(focal_rec);

%  Set the apodization

apo=hanning(N_active)';








