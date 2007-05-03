function this = testDrawTextureArgs()
    this = inherit ...
        ( TestCase() ...
        , public ...
            ( @init ... 
            , @testNormal ...
            , @testSubtract ...
            , @testMax ...
            , @testInvalid ...
            ) ...
        );

    params_ = struct();
    
    function initializer = init()
        initializer = joinResource ...
            ( getScreen ...
                ( 'backgroundColor', 0 ...
                , 'foregroundColor',  1 ...
                , 'requireCalibration', 0 ...
                , 'preferences.SkipSyncTests', 1 ...
                , 'preferences.Verbosity', 0 ...
                , 'preferences.SuppressAllWarnings', 1 ...
                ) ... 
            , @makeTextures ...
            , @setBlendFunction ...
            , @storeParams ...
            );
        
        function [r, params] = makeTextures(params);
            %make up some textures
            [x, y] = meshgrid( linspace(0, 1, 256), linspace(0, 1, 256) );
            a1 = (-cos(4 * 2 * pi * x) + 1) / 4 ...
               * (params.whiteIndex - params.blackIndex) + params.blackIndex;
            a2 = (-cos(4 * 2 * pi * y) + 1) / 4 ...
               * (params.whiteIndex - params.blackIndex) + params.blackIndex;
            
            params.tex1 = Screen('MakeTexture', params.window, a1);
            params.tex2 = Screen('MakeTexture', params.window, a2);
            
            r = @remove;
            function remove()
                if any(Screen('Windows') == params.window)
                    Screen('Close', params.tex1);
                    Screen('Close', params.tex2);
                end
            end
        end

        function [r, params] = setBlendFunction(params)
            %set the blend function to adding
            [oldSrc, oldDst] = Screen('BlendFunction', params.window, 'GL_SRC_ALPHA', 'GL_ONE');

            r = @reset;
            function reset()
                if (any(Screen('Windows') == params.window))
                    Screen('BlendFunction', params.window, oldSrc, oldDst);
                end
            end
        end
        
        function [r, params] = storeParams(params)
            params_ = params;
            r = @remove;
            function remove
                params_ = struct();
            end
        end
    end

    function testNormal
        Screen( 'DrawTexture', params_.window, params_.tex1);
        Screen( 'DrawTexture', params_.window, params_.tex2);
        Screen('Flip', params_.window);
        %should draw a plaid
        WaitSecs(0.5);
    end

    function testSubtract
        Screen('BlendEquation', params_.window, 'GL_FUNC_SUBTRACT');
        Screen( 'DrawTexture', params_.window, params_.tex1);
        Screen( 'DrawTexture', params_.window, params_.tex2);
        Screen('Flip', params_.window);
        %should draw rounded/diamond bumps
        WaitSecs(0.5);
    end

    function testMax
        Screen('BlendEquation', params_.window, 'GL_MAX');
        Screen( 'DrawTexture', params_.window, params_.tex1);
        Screen( 'DrawTexture', params_.window, params_.tex2);
        Screen('Flip', params_.window);
        %should draw a waffle without washing out
        WaitSecs(0.5);
    end
    
    function testInvalid
        flag = 0;
        try
            Screen('BlendEquation', params_.window, 'GL_FUNC_SUBTROCT');
            flag = 1;
            fail('expected an exception here');
        catch
            %expect an exception but the flag should be unset
            if flag
                rethrow(lasterror);
            end
        end
    end
end
