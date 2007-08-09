function initializer = GetScreen(varargin)
%initScreen(arguments)
%
%Produces an intialization function for use with REQUIRE, which:
%
%Obtains a Psychtoolbox window covering the maximum screen, with a gray
%background; we get some details about it, as well as calibration
%information, which is returned in a structure.
%
%Optional init structure fields:
%
%input structure fields:
%   backgroundcolor - the normalized background color to use. default 0.5
%   foregroundcolor - the foreground color, scale from 0 to 1. default 0.
%   preferences - the screen preferences to be set, as a structure. Default
%                       is preferences.SkipSyncTests = 0.
%   requireCalibration - whether to require calibration (answer)
%   cal -- optional input calibration to use
%
%output structure fields:
%   screenNumber - the screen number of the display
%   window - the PTB window handle
%   rect - the screen rectangle coordinates
%   cal - the calibration being used
%   blackIndex
%   whiteIndex
%   grayIndex - indexes into the colortable
%   foregroundIndex
%   backgroundIndex

%some defaults
defaults = namedargs ...
    ( 'backgroundColor', 0.5 ...
    , 'foregroundColor', 0 ...
    , 'preferences.SkipSyncTests', 0 ...
    , 'requireCalibration', 1 ...
    );

%curry arguments given now onto the initializer function
initializer = currynamedargs(@doGetScreen, defaults, varargin{:});
    
    function [release, details] = doGetScreen(details)
        
        %The initializer is composed of sub-initializers.
        initializer = joinResource(@checkOpenGL, @setPreferences, @setGamma, @openScreen, @blankScreen);
        [release, details] = initializer(details);

        %Now we define the sub-initializers. Each one is set up and torn down
        %in turn by the initializer defined by joinResource.

        %Step 0: run some assertions.
        function [release, details] = checkOpenGL(details)
            %just check for openGL and OSX.
            AssertOpenGL;
            AssertOSX;
            InitializeMatlabOpenGL;
            
            [release, details] = deal(@noop, details);
            function noop
            end
        end

        %Step 0.5: Set all screen preferences given.
        function [release, details] = setPreferences(details)
            %construct and run a chain of sub-initializers
            initializers = cellfun ...
                ( @preferenceSetter ...
                , fieldnames(details.preferences) ...
                , 'UniformOutput', 0);
            
            function init = preferenceSetter(name)
                init = @setPreference;
                function [r, params] = setPreference(params)
                    oldval = Screen('Preference', name, params.preferences.(name));
                    r = @()Screen('Preference', name, oldval);
                end
            end
            
            initializer = joinResource(initializers{:});
            
            [release, details] = initializer(details);
        end
        
        %Step 1: Pick the screen, and set the gamma to a calibrated value.
        function [release, details] = setGamma(details)

            screenNumber = max(Screen('Screens'));
            if ~isfield(details, 'cal') || isempty(details.cal)
                cal = Calibration(screenNumber);
            else
                cal = details.cal;
            end

            if (details.requireCalibration && ~cal.calibrated)
                error('getScreen:noCalibration'...
                    , 'No calibration was found for this system setup.' );
            end

            details.screenNumber = screenNumber;
            details.cal = cal;

            release = @resetGamma;

            %load the present table
            oldGamma = Screen('ReadNormalizedGammaTable', screenNumber);
            Screen('LoadNormalizedGammaTable', screenNumber, cal.gamma);

            function resetGamma
                Screen('LoadNormalizedGammaTable', screenNumber, oldGamma);
            end
        end

        %Step 2: Open a window on the screen.
        function [release, details] = openScreen(details)
            
            details.blackIndex = BlackIndex(details.screenNumber);
            details.whiteIndex = WhiteIndex(details.screenNumber);
            
            details.backgroundIndex = details.blackIndex + ...
                (details.whiteIndex - details.blackIndex) * details.backgroundColor;
            details.foregroundIndex = details.blackIndex + ...
                (details.whiteIndex - details.blackIndex) * details.foregroundColor;
            
            %note pattern: destructive function calls are the last in any
            %sub-initializer.
            try
                [details.window, details.rect] = ...
                    Screen('OpenWindow',details.screenNumber,details.backgroundIndex,[],32,2,0,0);
            catch
                %and yet, sometimes screen itself crashes and leaves a
                %window open...
                clear Screen;
                rethrow(lasterror)
            end
            
            release = @closeWindow;

            function closeWindow
                % close the window, if it's still open (it may have closed due
                % to a psychtoolbox error, because they think it's convenient to
                % close down the entire operation if you get an invalid argument
                % to DrawTexture)
                windows = Screen('Windows');
                if any(windows == details.window)
                    %message(details, 'Closing screen');
                    %pause(0.5);
                    Screen('Close', details.window);
                end
            end
        end

        %Step 3: Retreive some information and gray the screen
        function [release, details] = blankScreen(details)

            release = @noop;

            function noop
            end
        end
    end
end
