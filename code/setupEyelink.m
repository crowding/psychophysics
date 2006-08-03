function settings = setupEyelink(screenRect, arg)
% setupEyelink sets all standard defaults for eyelink used by Shadlen Lab
%
% Now includes all values that can be changed by the operator.
%
% Many other values are set in .ini files.
%
% Assumes eyelink is already initialized.
%
% Needs to know the screen rectangle, whcih is passed as first argument.
%
% Second optional argument is a structure.
%
% returns a struct containing all the defaults that were set.
%	arg structure used for future additions
% nothing returned
% John Palmer
%
% 6/6/01	Begun SetEyeLinkDefaults based on testcalib and testcalls
% 6/19/02	Renamed EXSetEyeLinkDefaults and included with other EX routines
%			added several commands, fixed head camera cammand (no = )
% 8/2/06    rewrote, returns struct with all the values set, and arg can
%           override those values

    rect = num2cell(screenRect);
    rectString = sprintf('%d %d %d %d', rect{:});

    settings = struct(...
        'screen_pixel_coords', rectString,...
        'active_eye', 'LEFT',...
        'binocular_enabled', 'NO',...
        'head_subsample_rate', 0,...
        'heuristic_filter', 'ON',...                % ON for filter (normal)
        'pupil_size_diameter', 'NO',...             % no for pupil area (yes for dia)
        'simulate_head_camera', 'NO',...            % NO to use head camera
        ...
        'calibration_type', 'HV9',...
        'enable_automatic_calibration', 'YES',...	% YES default
        'randomize_calibration_order', 'YES',...	% YES default
        'automatic_calibration_pacing', 1000,...	% 1000 ms default
        ...
        'saccade_velocity_threshold', 30,...
        'saccade_acceleration_threshold', 9500,...
        ...
        'file_event_filter', 'LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON',...
        'link_event_filter', 'LEFT,RIGHT,FIXATION,BUTTON',...
        'link_sample_data', 'LEFT,RIGHT,GAZE,AREA',...
        'randomize_validation_order', 'YES',... 	% YES default
        'analog_out_data_type', 'OFF',...           % YES default
        'file_sample_data', 'LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');

    if Eyelink('isconnected') == 0, 				% make sure it is connected
        error('Error in setupEyelink:  Eyelink not connected');
    end;

    %FIXME: eyelink does not return status
    %status = Eyelink('command', 'clear_screen 0');	% initialize screen on operater PC
    Eyelink('command', 'clear_screen 0');	% initialize screen on operater PC

    %override the default settings with arguments
    if exist('arg', 'var')
        for f = fieldnames(arg)
            field = f{:}; %strip field out of cell
            settings.(field) = arg.(field);
        end
    end


    for f = fieldnames(settings)'
        field = f{:}; %strip field out of cell
        %note: num2str('string') returns the same string
        commandstring = sprintf('%s = %s', field, num2str(settings.(field)));

        %FIXME: current eyelink beta does not return status from commands...
        Eyelink('Command', commandstring);
        %status = Eyelink('Command', commandstring);
        %if (status < 0)
        %    error('setupEyelink:badStatus', 'Status %d sending command "%s"',...
        %        status, commandstring);
        %end
    end

    message = sprintf('DISPLAY_COORDS %s', rectString);
    status = eyelink('Message', message);
    if (status < 0)
        error('setupEyelink:badStatus', 'Status %d sending message "%s"',...
            status, message);
    end

end
