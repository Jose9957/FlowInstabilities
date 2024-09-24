function bfM = SF_Mirror(bf)
%
% transforms a half mesh into a full mesh
%
%
% This is part of the StabFem project, copyright D. Fabre, july 2018.
%
% NB "backups in case of failure" are probably not useful anymore thanks
% to the new method to position entry files. To be checked and probably
% removed...
%
%global ff ffdir ffdatadir sfdir verbosity
%ffdatadir = SF_core_getopt('ffdatadir');

if strcmpi(bf.datatype,'mesh')
    halfmesh = bf;
    SF_core_log('d', 'FUNCTION SF_Mirror : mirroring mesh for single mesh');
    SFcore_MoveDataFiles(halfmesh.filename, 'mesh.msh','cp');
     % launch ff++ code
    SF_core_freefem('MirrorMesh.edp');
else %% LEGACY. Will only work for 2D-incompressible data
    halfmesh = bf.mesh;
    SF_core_log('d', 'FUNCTION SF_Mirror : mirroring mesh for single mesh+data');
    SFcore_MoveDataFiles(halfmesh.filename, 'mesh.msh','cp');
    SFcore_MoveDataFiles(bf.filename,'BaseFlow.txt','cp');
     % launch ff++ code
    SF_core_freefem('MirrorMesh_2D.edp');
end



% displace mesh in database
meshfilename = SFcore_MoveDataFiles('mesh_mirror.msh','MESHES');
ffmesh = SFcore_ImportMesh(meshfilename,'problemtype',halfmesh.problemtype);
ffmesh.symmetry = 'N';

% info
SF_core_log('n', '      ### MIRROR MESH : ');
SF_core_log('n', ['      #   Number of points np = ', num2str(ffmesh.np)] ); 

if strcmpi(bf.datatype,'mesh')
    bfM = ffmesh;
else
% displace dataset in database 
    SFcore_AddMESHFilenameToFF2M('BaseFlow_mirror.ff2m',meshfilename);
    finalname = SFcore_MoveDataFiles('BaseFlow_mirror.ff2m','MESHES','cp');
% import    
    bfM = SFcore_ImportData(finalname);  
% tweaks   
    if isfield(bf,'solver') 
        bfM.solver = bf.solver;
    end
    bfM.Symmetry = 'N';

end

end
