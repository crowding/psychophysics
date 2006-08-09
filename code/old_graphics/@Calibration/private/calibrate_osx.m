function readings = calibrate_osx(screenNumber);
%Tries to communicate with a LumaColor photometer connected by a serial port.
%(defaults to serial port 2)
%Sets the screen to each gray value 0:255 and reads the luminance.
%Returns the grayscales in the first column and the raw luminance values 
%in the second.

%The comm library being used will crash matlab at the slightest problem.
%Apparently there is a simple fix for this, which has not been made here.

port = 2;

try
	lasterr('');

	%open, probe for photometer, and flush the port
	comm('open', port, '2400,n,8,1');
	comm('write', port, sprintf('!NEW\r'));
	WaitSecs(1);
	string = comm('readl', port)
	if (length(string) == 0)
		error('no photometer detected');
	end
	comm('purge', port);

	%use the secondary monitor if there is one and no monitor is specified
	if (nargin < 1)
		screenNumber = max(Screen('screens'));
	end

	%Open a window
	
	%set flat gamma before opening window (because of the annoying warning 
	%display on OSX dual-head setups)
	gamma = Screen(screenNumber, 'LoadNormalizedGammaTable', ...
					linspace(0.5,0.5,256)'*[1 1 1]);
	[w, rect] = Screen('OpenWindow', screenNumber, [], [], 8);
	Screen('FillRect', w, 127);
	Screen('Flip', w);
	Screen('FillRect', w, 127);
	
	%set identity gamma table for the measurement
	gamma = Screen(screenNumber, 'LoadNormalizedGammaTable', ...
					linspace(0,1,256)'*[1 1 1]);

	%take luminance readings
	readings = [];
	for i = 0:255
		i
		Screen('FillRect', w, i);
		Screen('Flip', w);
		WaitSecs(3);
		tries = 0;
		reading = [];
		n_readings = 5;
		max_tries = 3;
		while (length(reading) < n_readings) & (tries < max_tries)
			%talk to the photometer and try to obtain 3 readings.
			comm('write', port, sprintf('!NEW %d\r', n_readings));
			WaitSecs(2);
			response = 'x';
			while length(response) > 0
				response = comm('readl', port);
	
				%use regexp to match...
				response = regexp(response, '\d[^\n\r]*', 'match');
				
				if (length(response) > 0)
					reading = cat(1, reading, sscanf(response{1}, '%f'));
				end
			end
	
			if (length(reading) < 3)
				if (tries >= 3)
					disp('this should abort?');
					error('error reading from photometer');
				elseif (tries < 3)
					warning('retrying...');
					tries = tries + 1
				end
			end
		end
		readings = cat(1, readings, [i mean(reading)]);
	end

	readings = sortrows(readings);
	
	error('calibration:finally','finally'); %gah, matlab has no finally clause
catch
	err = lasterror;
	try
		disp 'closing screen'
		Screen('Close', w);
	end
	try
		comm('close', port);
	end
	if ~strcmp(err.identifier, 'calibration:finally')
		rethrow(err);
	end
end
