function glSampleMaskSGIS( arg1, arg2 )

% glSampleMaskSGIS  Interface to OpenGL function glSampleMaskSGIS
%
% usage:  glSampleMaskSGIS( arg1, arg2 )
%
% C function:  void glSampleMaskSGIS(GLclampf, GLboolean)

% 30-May-2006 -- created (generated automatically from header files)

if nargin~=2,
    error('invalid number of arguments');
end

moglcore( 'glSampleMaskSGIS', arg1, arg2 );

return
