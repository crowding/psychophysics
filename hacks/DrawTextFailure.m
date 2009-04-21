function DrawTextFailure

s = max(Screen('Screens'));
w = Screen('OpenWindow', s);
VBL = Screen('Flip', w);
count = 0;
FlushEvents()
while ~CharAvail()
    Screen('DrawText', w, sprintf('drawn at %d %f', count, GetSecs()), 100, 100);
    VBL = Screen('Flip', w, 0);
    count = count + 1;
end
Screen('CloseAll');