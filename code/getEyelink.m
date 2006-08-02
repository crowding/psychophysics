function [release, details] = getEyelink(details)
%
%An intialization function for use with REQUIRE.
%
%An initializer which connects to the Eyelink system, running the
%calibration and choosing an file name; cleans up the connection at close.
%
%Input structure fields:
%   window - the PTB window number
%
%Output structure fields:
%   el - the eyelink info structure
%   edfname - the EDF file name
%   localname - full path to where the EDF file is downloaded locally
%   dummy - whether the eyelink was opened in dummy mode
    
    initializer = joinResource(@connect, @initDefaults, @doSetup, @openEDF);
    [release, details] = initializer(details);
    
%sub-initializers:

    %open/close the eyelink connection
    function [release, details] = connect(details)
        %connect to the eyelink machine.
        try
            status = Eyelink('Initialize');
            details.dummy = 0;
        catch
            warning('Using eyelink in dummy mode')
            status = Eyelink('InitializeDummy');
            details.dummy = 1;
        end
        
        if status < 0
            error('getEyelink:initFailed',...
                'Initialization status %d', status);
        end
        
        [release, details] = deal(@close, details);
        
        function close
            Eyelink('Shutdown'); %no output argument
        end
    end


    %initialize eyelink defaults. Requires the 'window' field from getScreen.
    function [release, details] = initDefaults(details)
        el = EyelinkInitDefaults(details.window);
        details.el = el;
        [release, details] = deal(@noop, details);
        
        function noop
            %While EyelinkInitDefaults changes the eyelink's screen
            %resolution settings, there is no way to tell what the setings
            %were before, so there is nothing to be done for cleanup.
        end
    end


    %do the tracker setup. Requires the 'el' field from initDefaults.
    function [release, details] = doSetup(details)
        disp('Do tracker setup now');
        status = EyelinkDoTrackerSetup(details.el, details.el.ENTER_KEY);
        if status < 0
            error('getEyelink:TrackerSetupFailed', 'Eyelink setup failed.');
        end
        
        [release, details] = deal(@noop, details);
        
        function noop
            %nothing to undo
        end
    end

    %open the eyelink data file on the eyelink machine
    %input field: dummy: skips a file check in dumy mode
    %output field: edfFilename = the name of the EDF file created
    function [release, details] = openEDF(details)
        e = env;
        %pick some kind of unique filename by combining a prefix with
        %an encoding of the date and time
        
        pause(1); % to make it likely that we get a unique filename, hah!
                  % oh, why is the eyelink so dumb?
        
        edfname = ['z' clock2filename(clock) '.edf'];
        localname = fullfile(e.eyedir, edfname);
        details.edfname = edfname;
        %make a note of where we will find the file locally
        details.localname = localname;
       
        %the eyelink has no way directly to check that the filename is
        %valid or non-existing... so we must assert that we can't open the
        %file yet.
        tmp = tempname();
        status = Eyelink('ReceiveFile',edfname,tmp);
        if (~details.dummy) && (status ~= details.el.FILE_CANT_OPEN)
            error('Problem generating filename (expected status %d, got %d)',...
                details.el.FILE_CANT_OPEN, status);
        end
        
        %destructive step: open the file
        status = Eyelink('OpenFile', edfname);
        if (status < 0)
            error('getEyelink:fileOpenError', ...
                'status %d opening eyelink file %s', status, edfname);
        end
        
        %when we are done with the file, download it
        release = @downloadFile;
        
        function downloadFile
            %try both in any case
            status = Eyelink('CloseFile');
            fsize = Eyelink('ReceiveFile', edfname, localname);
            
            if (fsize < 1 || status < 0)
                error('getEyeink:fileTransferError', ...
                    'File %s empty or not transferred (close status: %d, receive: %d)',...
                    edfname, status, fsize);
            end
        end
    end
end