

function [bf]= SmartMesh_Cylinder(type,dimensions)
% THIS little functions generates and adapts a mesh for the wake of a cylinder.
% Adaptation type is either 'S' (mesh M2) or 'D' (mesh M4).

if(nargin==0)
    type='S';
    MeshOptions = {'Xmin',-40,'Xmax', 80,'Ymax', 40};
end

if(nargin==1)
    MeshOptions = {'Xmin',-40,'Xmax', 80,'Ymax', 40};
end

ffmesh = SF_Mesh('Mesh_Cylinder.edp','Options',MeshOptions,'problemtype','2D','cleanworkdir','yes'); % obsolete syntax for problemtype
bf=SF_BaseFlow(ffmesh,'Re',1);

bf=SF_BaseFlow(bf,'Re',10);
bf=SF_BaseFlow(bf,'Re',60);
bf=SF_Adapt(bf,'Hmax',5);
bf=SF_Adapt(bf,'Hmax',5);
disp(' ');
disp(['mesh adaptation  : type ',type])
[ev,em] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','A');
bf=SF_Adapt(bf,em,'Hmax',5);
if strcmp(type,'S') % adaptation to sensitivity
  [ev,em] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','A');
  [ev,emD] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','D');  
  emS = SF_Sensitivity(bf,emD,em);
  bf=SF_Adapt(bf,emS,'Hmax',5);
elseif strcmp(type,'A')  % adaptation to Adjoint mode
 [ev,em] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','A');
  bf=SF_Adapt(bf,em,'Hmax',5);
else % adaptation to direct mode
    [ev,emD] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','D');
    bf=SF_Adapt(bf,em,'Hmax',5);
end

disp([' Adapted mesh has been generated ; number of vertices = ',num2str(bf.mesh.np)]);


end