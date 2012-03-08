function x = backchannel(action, value)
    persistent stored;

    switch(action)
        case 'store'
            stored = value;
        case 'recall'
            x = stored;
    end     
end