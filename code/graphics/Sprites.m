function this = Sprites(varargin)
%displays one or more images on the screen.

    %what images to show. This must be set before the experiment starts.
    %They can be MxNx(1,3,4) arrays, or filenames, or functions or evaluable objects
    %(in which case the objects are evaluated to make an array.) or mere 
    images = {};
    textureHandles_ = [];
    pixSizes_ = [];
    
    %the x, y, coordinates to place the image(s) at; this can also be an
    %evaluable function or object.
    loc = [0;0];
    
    %how large to make the image (in degrees per pixel) Use NaN to display
    %as pixel-for-pixel.
    scale = NaN;
    
    %what images to show. This can also be an evaluable function.
    index = 1;
    
    %antialias; default if you are smoothly moving or scaling the image.
    %If you want to round to the nearest pixel, set to 0.
    antialias = 1;
    
    %fill this out, or eval it, if you want to use that feature of
    %drawTextures...
    sourceRects = [];
    
    %rotation angle...
    rotate = 0;
    
    %set to 0 to disable drawing.
    visible = 1;
    toPixels_ = @noop;
    
    persistent init__; %#ok
    this = autoobject(varargin{:});

    function [release, params, next] = init(params) %#ok
        %Now, this is done for each trial. If that is a performance problem
        %we might try to work a way to have it done once for all trials.
        
        %load the images into textures.
        if (~iscell(images))
            images = num2cell(images);
        end
        
        textureHandles_ = zeros(1, numel(images));
        pixSizes_ = zeros(2, numel(images));
        
        toPixels_ = transformToPixels(params.cal);
        
        loaders = cellfun(@loader, images, num2cell(1:numel(images)), 'UniformOutput', 0);
        next = joinResource(loaders{:});
        release = @noop;
        
        function l = loader(img, i)
            l = @loadImage;
            
            function [release, params] = loadImage(params)
                if ischar(img)
                    [imageData, map, alpha] = imread(img);
                    
                    %here lies another very very weird behavior of matlab
                    %indexing: imageData is suddenly and without warning
                    %treated as a vector.
                    %imageData = reshape(map(double(imageData+1,:),
                    %[size(imageData) 3
                    s = size(imageData);
                    pixSizes_(:,i) = s([1 2]);
                    
                    imageData = ind2rgb(imageData, map);
                    
                    if ~isempty(alpha)
                        imageData(:,:,4) = alpha;
                    end
                else
                    imageData = e(img, params);
                    s = size(imageData);
                    pixSizes_(:,i) = s([1 2]);
                end
                
                textureHandles_(i) = Screen('MakeTexture', params.window, imageData.*255); 
                release = @r;
                function r
                    %unload the texture
                    Screen('Close', textureHandles_(i));
                end
            end
        end
    end

    function draw(window, next, params) %#ok
        if(visible)
            %draw each image...
            l = e(loc, next);
            sc = e(scale, next);
            ix = e(index, next);
            r = e(rotate, next);
            sr = e(sourceRects, next);
            
            orig = isnan(sc(ix));
            d = zeros(4, numel(ix));
            d(:,~orig) = toPixels_(l([1 2 1 2],~orig) + bsxfun(@times, sc(:)', [-pixSizes_([2 1],ix(~orig)); pixSizes_([2 1],ix(~orig))])/2);
            d(:,orig) =  toPixels_(l([1 2 1 2], orig)                        + [-pixSizes_([2 1],ix( orig)); pixSizes_([2 1],ix( orig))] /2);
            
            Screen('DrawTextures', window, textureHandles_(ix), sr, d, r, antialias);
        end
    end

    function update(frames)
        
    end

    %{
    function setImages(i) %#ok
        %if performance is a problem, we might want to cache the texture
        %handles...
        textureHandles_ = [];
        images = i;
    end
    %}
end