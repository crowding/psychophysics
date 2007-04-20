function this = testDrawTextureArgs()
    this = inherit ...
        ( TestCase() ...
        , public ...
            ( @init ... 
            , @testNormals ...
            , @testChangeSrcFactorOnly ...
            , @testChangeDstFactorOnly ...
            , @testChangeBothFactors ...
            ) );

        %{
                        , @testChangeBothFactors ...
            , @testInvalidSrcFactors ...
            , @testInvalidDstFactors ...
            , @testInvalid ...

            %}
    
    params_ = struct();
    
    function initializer = init()
        initializer = joinResource ...
            ( getScreen ...
                ( 'backgroundColor', 0 ...
                , 'foregroundColor',  1 ...
                , 'preferences.SkipSyncTests', 1 ...
                , 'preferences.Verbosity', 1 ...
                , 'preferences.SuppressAllWarnings', 1 ...
                ) ... 
            , @makeTextures ...
            , @storeParams ...
            );
        
        function [r, params] = makeTextures(params);
            %make up some textures
            [x, y] = meshgrid( linspace(0, 1, 256), linspace(0, 1, 256) );
            a1 = (-cos(2 * 2 * pi * x) + 1) / 4 * (params.whiteIndex - params.blackIndex) + params.blackIndex;
            a2 = (-cos(4 * 2 * pi * y) + 1) / 4 * (params.whiteIndex - params.blackIndex) + params.blackIndex;
            
            params.tex1 = Screen('MakeTexture', params.window, a1);
            params.tex2 = Screen('MakeTexture', params.window, a2);
            
            r = @remove;
            function remove()
                Screen('Close', params.tex1);
                Screen('Close', params.tex2);
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

    function testNormals
        Screen('DrawTexture', params_.window, params_.tex1, [], [], [], [], []);
        Screen('Flip', params_.window);
        Screen('DrawTexture', params_.window, params_.tex2, [], [], [], [], []);
        Screen('Flip', params_.window);
        %should draw 4 horizontal stripes
    end

    function testChangeSrcFactorOnly
        Screen('DrawTexture', params_.window, params_.tex1, [], [], [], 'GL_ONE', []);
        Screen('Flip', params_.window);
        Screen('DrawTexture', params_.window, params_.tex2, [], [], [], hex2dec('0306'), []); %GL_DST_COLOR
        Screen('Flip', params_.window);
        %should draw a weak plaid
    end

    function testChangeDstFactorOnly
        Screen('DrawTexture', params_.window, params_.tex1, [], [], [], [], 1); %GL_ONE
        Screen('Flip', params_.window);
        Screen('DrawTexture', params_.window, params_.tex2, [], [], [], [], 'GL_SRC_COLOR');
        Screen('Flip', params_.window);
        %should draw bumps on top of stripes
    end

    function testChangeBothFactors
        Screen('DrawTexture', params_.window, params_.tex1, [], [], [], 'GL_ONE', 1);
        Screen('Flip', params_.window);
        Screen('DrawTexture', params_.window, params_.tex2, [], [], [], 1, 'GL_ONE');
        Screen('Flip', params_.window);
        %should draw a plaid
    end
end