function Mask = SF_Mask(mesh,type,params)
%
% function SF_Mask
% 
% The role of this function is to create an "adaptation mask", i.e. a set
% of data which, when using subsequently with SF_Adapt, will force the mesh
% adaptor to respect a minimum grid size (delta) within a given domain.
% 
% USAGE :
%   Mask = SF_Mask(mesh,'type',[ Parameters ]) 
% 
%   the second input 'type' is selected among 'rectangle', 'ellipse',
%   'trapeze' (and possibly a few more in development). If absent
%   'rectangle' is assumed.
% 
%  the second parameter is an of numerical parameters whose meaning depend
%  upon the case :
%
%  - for 'rectangle' : [ Xmin, Xmax, Ymin, Ymax, delta]
%                      (dimensions of the rectangle)
%
% - for 'ellipse' : [ Xc, Yc, Lx, Ly, delta]
%                   ( coordinates of the center, and semiaxes )
%
% - for 'trapeze' : [ Xmin, Xmax, Ymin, Ymax,  theta1, theta2, delta]
%                   ( works like a rectangle but will be stretched into a trapeze; 
%                    NB here the angles are in degrees. Use theta1<0 and theta2>0 to enlarge 
%                    the region you expect to remesh )
%
% This program is part of the StabFem project distributed under gnu licence.

 if(strcmpi(mesh.datatype,'mesh')==0)
       % first argument is most likely a base flow
       mesh = mesh.mesh;
 end

 if (nargin <3)
     SF_core_log('l',' Mask type not specified ... assuming rectangle');
     params = type;
     type = 'rectangle';
 elseif isnumeric(type)
     SF_core_log('l',' it is now advised to use in this way : SF_Mask([mesh or bf],[type],[Parameters]');
     type2 = type;
     type=params;
     params = type2;
 end
     
 
 
   SFcore_MoveDataFiles(mesh.filename,'mesh.msh','cp');
switch(type)
    case('rectangle')
         optionstring = [ 'rectangle ' num2str(params(1)) ' ' num2str(params(2)) ' ' ...
                  num2str(params(3)) ' ' num2str(params(4)) ' ' num2str(params(5)) ];
    case('ellipse')
         optionstring = [ 'ellipse ' num2str(params(1)) ' ' num2str(params(2)) ' ' ...
                  num2str(params(3)) ' ' num2str(params(4)) ' ' num2str(params(5)) ];
    case('trapeze')
         optionstring = [ 'trapeze ' num2str(params(1)) ' ' num2str(params(2)) ' ' ...
                  num2str(params(3)) ' ' num2str(params(4)) ' ' num2str(params(5)) ... 
                  ' ' num2str(params(6)) ' ' num2str(params(7)) ];          
    case('thermal7')
         optionstring = [ 'thermal7 ' num2str(params(1)) ];
     case('thermal27')
         optionstring = [ 'thermal27 ' num2str(params(1)) ];     
end
                  
SF_core_freefem('AdaptationMask.edp','parameters',optionstring);  


% We import using the new method 
SFcore_AddMESHFilenameToFF2M('Mask.txt',mesh.filename);   
filename = SFcore_MoveDataFiles('Mask.txt','MISC');
Mask = SFcore_ImportData(mesh,filename);

end
