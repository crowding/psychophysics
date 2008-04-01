function this = Subscripter()
%With a Subscripter object, you can subscript things on the fly, such as
%the results of function calls.

persistent shared; %singleton -- don't need more than one instance, there is no data here, just an abuse of overloading.
if isnumeric(shared)
    shared = class(struct(), mfilename('class'));
end

this = shared;