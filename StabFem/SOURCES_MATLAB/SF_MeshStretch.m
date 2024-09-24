function fffield = SF_MeshStretch(fffield, varargin)
%
% This is part of StabFem Project, D. Fabre, July 2017 -- present
% Matlab driver for StretchMesh
%
% Usage : 1/ (for fress surface problems)
%   ffmesh = SF_MeshStretch(ffmesh,[opt,val])
%         2/ for base-flow associated problems
%   bf = SF_MeshStretch(bf,[opt,val])

%
% The mesh will be stretched in both X(R) and Y(Z) directions. 
% Note that the resulting mesh is not necessarily an equilibrium shape ! use
%

%global ff ffdir ffdatadir sfdir verbosity

ffdatadir = SF_core_getopt('ffdatadir');

%%% TO BE SFCOREIZED

% Interpreting parameters
p = inputParser;
addParameter(p, 'Xratio', 1);
addParameter(p, 'Yratio', 1);
addParameter(p, 'Xmin', 0);
addParameter(p, 'Ymin', 0);
parse(p, varargin{:});


if(strcmpi(fffield.datatype,'mesh'))
    ffmesh = fffield;
else
    ffmesh = fffield.mesh;
end
problemtype = ffmesh.problemtype; 


% designation of the adapted mesh
if(isfield(ffmesh,'meshgeneration'))
     meshgeneration = ffmesh.meshgeneration+1;
else
    meshgeneration = 1;
    disp('WARNING : no mesh generation in SF_MeshStretch');
end
designation = ['_stretch',num2str(meshgeneration)]; % OBSOLETE ! to be removed

SFcore_MoveDataFiles(ffmesh.filename,'mesh_guess.msh','cp');
if ~strcmpi(ffmesh.problemtype,'3dfreesurfacestatic')&&~strcmpi(ffmesh.problemtype,'axifsstatic')
    SFcore_MoveDataFiles(fffield.filename,'BaseFlow.txt','cp');
else
    SFcore_MoveDataFiles(fffield.filename,'FreeSurface.txt','cp'); %actually this is not useful
end
paramstring = [ num2str(p.Results.Xratio), ' ', num2str(p.Results.Yratio), ' ', num2str(p.Results.Xmin), ' ', num2str(p.Results.Ymin)];

%% call to ff solver

status = SF_core_freefem('MeshStretch.edp','parameters',paramstring);

%% post tasks

newmeshfilename = SFcore_MoveDataFiles('mesh_stretched.msh','MESHES');
ffmesh = SFcore_ImportMesh(newmeshfilename);
ffmesh.problemtype = problemtype;
ffmesh.generation = meshgeneration;

if(strcmpi(fffield.datatype,'mesh'))
    % first argument was a mesh ; then result is also the mesh
    fffield=ffmesh;
    
elseif ~strcmpi(ffmesh.problemtype,'3dfreesurfacestatic')&&~strcmpi(ffmesh.problemtype,'axifsstatic')
    % first argument was a baseflow ; then result will be a baseflow will be recomputed
    fffield.mesh=ffmesh;
    
    SF_core_log('n',' SF_MeshStretch : recomputing base flow after STRETCH');
    SFcore_AddMESHFilenameToFF2M(fffield.filename,fffield.mesh.filename);   
    finalname = SFcore_MoveDataFiles(fffield.filename,'MISC','cp');
    baseflowNew  = SF_BaseFlow(fffield, 'type', 'POSTADAPT'); 
     if (baseflowNew.iter > 0)
     fffield = baseflowNew; 
     finalname = SFcore_MoveDataFiles(baseflowNew.filename,'MESHES','cp');

     else
         error('ERROR in SF_Adapt : baseflow recomputation failed');
     end
else % for 3d static problems
    SFcore_AddMESHFilenameToFF2M('FreeSurface_stretch.txt',ffmesh.filename); 
    finalname = SFcore_MoveDataFiles('FreeSurface_stretch.txt','MESHES');   
    fffield = SFcore_ImportData(finalname);
    
end


end

