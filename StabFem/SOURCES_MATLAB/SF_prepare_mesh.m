%% Convert FreeFem++ mesh connectivity to nodal coordinates
%
% Author: David Fabre
% adapted from Chloros2 <chloros2@gmx.de> 2018-12-18 / 
%
% USAGE :
% [xmesh,xpts,ymesh,ypts] = prepare_mesh(points,triangles,xix,xiy)


%% Code
function [xmesh,xpts,ymesh,ypts] = SF_prepare_mesh(points,triangles,xix,xiy)
%    disp( 'using SF_prepare_mesh to deform mesh'); 
    xpts=points(1,:);
    ypts=points(2,:);
    xmesh=[xpts(triangles(1,:)); xpts(triangles(2,:)); xpts(triangles(3,:))];
    ymesh=[ypts(triangles(1,:)); ypts(triangles(2,:)); ypts(triangles(3,:))];
     
    
    if length(xix)==size(xmesh,2)*6
        xmesh(1,:) = xmesh(1,:)+xix(1:6:end)';
        xmesh(2,:) = xmesh(2,:)+xix(2:6:end)';
        xmesh(3,:) = xmesh(3,:)+xix(3:6:end)';
        ymesh(1,:) = ymesh(1,:)+xiy(1:6:end)';
        ymesh(2,:) = ymesh(2,:)+xiy(2:6:end)';
        ymesh(3,:) = ymesh(3,:)+xiy(3:6:end)';
    elseif length(xix)==size(xmesh,2)*3
        xmesh(1,:) = xmesh(1,:)+xix(1:3:end)';
        xmesh(2,:) = xmesh(2,:)+xix(2:3:end)';
        xmesh(3,:) = xmesh(3,:)+xix(3:3:end)';
        ymesh(1,:) = ymesh(1,:)+xiy(1:3:end)';
        ymesh(2,:) = ymesh(2,:)+xiy(2:3:end)';
        ymesh(3,:) = ymesh(3,:)+xiy(3:3:end)';
    else
        SF_core_log('w','in plotting deformed mesh with SF_prepare_mesh : unrecognized dimensions'); 
    end
    
end
