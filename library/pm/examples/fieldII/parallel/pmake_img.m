%  Compress the data to show 60 dB of
%  dynamic range for the cyst phantom image

% needed inputs:
%no_lines   
%fname         %  Partly filename of source envelope data
%fs            %  Sampling frequency [Hz]
%image_width   %  Size of image sector
%d_x           %  Increment for image

%  Read the data and adjust it in time 

env = zeros(1,no_lines); % preallocate
for i=1:no_lines

  %  Load the envelope
  
  cmd=['load ' fname sprintf('%d',i) '.mat'];
  eval(cmd)
  
  env(1:length(rf_env),i)=rf_env(:);
end

%  Do logarithmic compression

D=10;   %  Sampling frequency decimation factor

log_env=env(1:D:max(size(env)),:)/max(max(env));
log_env=log(log_env+0.01);
log_env=log_env-min(min(log_env));
log_env=64*log_env/max(max(log_env));

%  Make an interpolated image

ID=20;
[n,m]=size(log_env)
new_env=zeros(n,m*ID);
for i=1:n
%  if (rem(i,100) == 0)
%     i
%    end
  new_env(i,:)=abs(interp(log_env(i,:),ID));
  end
[n,m]=size(new_env)
  
fn=fs/D;
clf
image(((1:(ID*no_lines-1))*d_x/ID-no_lines*d_x/2)*1000,((1:n)/fn)*1540/2*1000,new_env)

xlabel('Lateral distance [mm]')
ylabel('Axial distance [mm]')
colormap(gray(64))
brighten(0.2)
axis('image')
axis([-20 20 35 90])




