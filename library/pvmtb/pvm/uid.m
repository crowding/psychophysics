function str = uid()
%UID			Devuelve el user-id según Unix (id -u) como string
%
%  'str' = uid
%
%  Implementación M total

[retcode str]=unix('id');
str=str(findstr(str,'=')+1:findstr(str,'(')-1);

