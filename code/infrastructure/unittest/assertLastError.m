function assertLastError(fragment)
%ASSERTLASTERROR(fragment)
%
%Asserts that the identifier last error received matches the identifier
%fragment (as in ERRORMATCH.)
err = lasterror;




if ~errormatch(fragment, err.identifier)
    %we want to throw, but also want to attach the improper exception.
    %since dbstack() produces different output than error(), we will have
    %to use error().
    try
        error('assert:assertionFailed', 'expected error "%s", got "%s"', fragment, err.identifier);
    catch
        newerr = lasterror;
    end
    
    %attach the failed error
    error(adderror(newerr, err));
end