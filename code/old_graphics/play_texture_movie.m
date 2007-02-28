function play_texture_movie(textures, w)

black = BlackIndex(w);
white = WhiteIndex(w);
gray = (black + white)/2;

cframe = textures(1).frame;
for t = textures(:)'
	if (t.frame > cframe)
		%display this frame
		Screen('Flip', w);
		
		%start next frame
		Screen('FillRect', w, gray);
		cframe = cframe + 1;
    end
    
    glBlendEquation(t.blendEquation);
    Screen('BlendFunction', w, t.sourceFactor, t.destFactor);
	Screen('DrawTexture', w, t.texture, [], t.playrect);
end