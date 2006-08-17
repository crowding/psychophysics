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
%   [none] (input structure optional)
%
%output structure fields:
%   screenNumber - the screen number of the display
%   window - the PTB window handle
%   rect - the screen rectangle coordinates
%   cal - the calibration being used
%   black
%   white
%   gray - indexes into the colortable

%curry arguments given now onto the initializer function
curry = varargin;
initializer = setnargout(nargout(@doGetScreen), @(varargin)doGetScreen(curry{:}, varargin{:}));

    function [release, details] = doGetScreen(details)
        %input structure is optional
        if ~exist('details', 'var')
            details = struct;
        end

        %The initializer is composed of sub-initializers.
        initializer = joinResource(@checkOpenGL, @setGamma, @openScreen, @blankScreen);
        [release, details] = initializer(details);

        %Now we define the sub-initializers. Each one is set up and torn down
        %in turn by the initializer defined by joinResource.

        %Step 0: run some assertions.
        function [release, details] = checkOpenGL(details)
            %just check for openGL and OSX.
            AssertOpenGL;
            AssertOSX;

            [release, details] = deal(@noop, details);
            function noop
            end
        end

        %Step 1: Pick the screen, and set the gamma to a calibrated value.
        function [release, details] = setGamma(details)

            screenNumber = max(Screen('Screens'));
            cal = Calibration(screenNumber);

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

            %note pattern: destructive function calls are the last in any
            %sub-initializer.
            [window, rect] = Screen('OpenWindow',details.screenNumber,0,[],[],2);
            [details.window,details.rect] = deal(window, rect);

            release = @closeWindow;
            function closeWindow
                Screen('Close', window);
            end
        end

        %Step 3: Retreive some information and gray the screen
        function [release, details] = blankScreen(details)
            %TODO: this would be better done with a 'background' graphics object

            details.black = BlackIndex(details.window);
            details.white = WhiteIndex(details.window);
            details.gray = GrayIndex(details.window);

            Screen('FillRect', details.window, details.gray);
            Screen('Flip', details.window);
            Screen('FillRect', details.window, details.gray);

            release = @noop;

            function noop
            end
        end
    end
end