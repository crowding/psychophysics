%test whether events arrive from the mouse with accurate timing...
%keep your mouse moving continuously during this test. 

%Answer: they arrive as often as you poll them, or every millisecond, whichever is slower

d = PsychHID('devices')
d = find(strcmp({d.usageName}, 'Mouse'));

options = struct('secs', 0);

Priority(9);

reports = cell(500, 1);
times = zeros(500, 1);

for i = 1:500
    r = [];
    while isempty(r)
        times(i) = GetSecs();
        PsychHID('ReceiveReports', d, options);
        r = PsychHID('GiveMeReports', d);
    end
    reports{i} = r;
    WaitSecs(1/10); % oddly enough no matter how long you wait here it seems to be ccurate to 2 ms
end

Priority(0);

reps = cat(2, reports{:})

clf
hist(diff(times), 0.00025:0.0005:0.10025, 'r')
hold on
hist(diff([reps.time]), 0.00025:0.0005:0.10025, 'b')
hold on
