
% prefun: initialisation of xmit_aperture, receive_aperture, use_triangles, set_sampling, excitation, impulsion
% Nft, Nfr after getting focals

% specific variables needed: apo_vector, x

% common variables required:
% focus_times_rec, focal_rec, focal_xmit, focus_times_xmit
% load: phantom_positions,phantom_amplitudes 

% output: save: rf_data, tstart;

% postfun : clear xdc

%   Set the focus for this direction with the proper reference point
%  x = -image_width/2 +(k-1)*d_x;

  xdc_center_focus (xmit_aperture, [x 0 0]);
  xdc_focus (xmit_aperture, focus_times_xmit, [x*ones(Nft,1), zeros(Nft,1), focal_xmit]);
  xdc_center_focus (receive_aperture, [x 0 0]);
  xdc_focus (receive_aperture, focus_times_rec, [x*ones(Nfr,1), zeros(Nfr,1), focal_rec]);

   %  Calculate the apodization 
   
  N_pre  = round(x/(width+kerf) + N_elements/2 - N_active/2);
  N_post = N_elements - N_pre - N_active;
  apo_vector=[zeros(1,N_pre) apo zeros(1,N_post)];   

  xdc_apodization (xmit_aperture, 0, apo_vector);
  xdc_apodization (receive_aperture, 0, apo_vector);
  
  %   Calculate the received response

  [rf_data, tstart]=calc_scat(xmit_aperture, receive_aperture, phantom_positions, phantom_amplitudes);





