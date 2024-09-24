function fffield = SF_SetMapping(fffield, varargin)
%
% This is part of StabFem Project, D. Fabre, July 2017 -- present
% Matlab Driver to specify the mapping
%
% Usage : 1/ (for linear acoustic problems or other nonrelated to bf)
%   ffmesh = SF_SetMapping(ffmesh,'MappingType',type,'MappingParam',Params)
%         2/ for base-flow associated problems
%   bf = SF_SetMapping(bf,'MappingType',type,'MappingParam',Params)
%
%  Params is a vector whose size depends on the type. Currently implemented
%  cases are as follows :
%  typemapping = "jet" -> Params = [Lm, LA, LC, gammaC, yA, yB]
%  typemapping = "box" -> Params = [xinf,xsup,yinf,ysup,gammaCx,LCx,gammaCy,LCy]
%  typemapping = "spherical" -> Params = ... (to be implemented...)
%
%

%global ff ffdir ffdatadir sfdir verbosity
ffdatadir = SF_core_getopt('ffdatadir');

% Interpreting parameters
p = inputParser;
addParameter(p, 'MappingType', 'jet'); % Array of parameters for the cases involving mapping
addParameter(p, 'MappingParams', 'default'); % Array of parameters for the cases involving mapping
parse(p, varargin{:});


if(strcmpi(fffield.datatype,'mesh'))
    ffmesh = fffield;
else
    ffmesh = fffield.mesh;
end

% designation of the adapted mesh
if(isfield(ffmesh,'meshgeneration'))
     meshgeneration = ffmesh.meshgeneration+1;
else
    meshgeneration = 1;
    disp('WARNING : no mesh generation in SF_MeshStretch');
end
%designation = ['_stretch',num2str(meshgeneration)];
% this desingation will be added to the names of the mesh/BF files


%%

    mycp(ffmesh.filename, [ffdatadir, 'mesh.msh']); % position mesh file
    
     createMappingParamFile(p.Results.MappingType,p.Results.MappingParams); %% See auxiliary function at the end of this file
%    command = [ ff, ' ', ffdir, 'SetMapping.edp'];
%    errormsg = 'ERROR : FreeFem SetMapping aborted';
%    status = mysystem(command, errormsg); 


%mycp(ffmesh.filename, [ffdatadir, 'mesh_guess.msh']); % position mesh file
%command = ['echo ', num2str(p.Results.Xratio), ' ', num2str(p.Results.Yratio), ' ', num2str(p.Results.Xmin), ' ', num2str(p.Results.Ymin),  ' | ', ff, ' ', ffdir, 'MeshStretch.edp'];
%errormsg = 'ERROR : FreeFem MeshStretch aborted';
%status = mysystem(command, errormsg);
%mycp('WORK/mesh_guess.msh',[ffdatadir,'MESHES/mesh',designation,'.msh']);
%mycp('WORK/mesh_guess.ff2m',[ffdatadir,'MESHES/mesh',designation,'.ff2m']);
%ffmesh = importFFmesh([ffdatadir,'MESHES/mesh',designation,'.msh']);
%ffmesh.generation = meshgeneration;


if(strcmpi(fffield.datatype,'mesh'))
    % first argument was a mesh ; then result is also the mesh
    fffield=ffmesh;
    
else
    
    % designation of the adapted mesh
    if(isfield(ffmesh,'meshgeneration'))
     meshgeneration = ffmesh.meshgeneration+1;
    else
    meshgeneration = 1;
    disp('WARNING : no mesh generation in SF_MeshStretch');
    end
    designation = ['_mapped',num2str(meshgeneration)];
    
    % first argument was a baseflow ; then baseflow will be recomputed
    fffield.mesh=ffmesh;
     mydisp(2,' SF_Adapt : recomputing base flow');
    baseflowNew  = SF_BaseFlow(fffield, 'type', 'POSTADAPT'); 
     if (baseflowNew.iter > 0)
     fffield = baseflowNew; 
     
%     mycp('WORK/mesh.msh',[ffdatadir,'MESHES/mesh',designation,'.msh']);
%     mycp('WORK/mesh.ff2m',[ffdatadir,'MESHES/mesh',designation,'.ff2m']);
%     ffmesh = importFFmesh([ffdatadir,'MESHES/mesh',designation,'.msh']);
%     ffmesh = SFcore_ImportMesh([ffdatadir,'MESHES/mesh',designation,'.msh']);
      newname = SFcore_MoveDataFiles('mesh.msh',['MESHES/mesh',designation,'.msh']);
      ffmesh = SFcore_ImportMesh(newname);
     
%     mycp([ffdatadir, 'BaseFlow.txt'],  [ffdatadir, 'MESHES/BaseFlow', designation, '.txt']);
%     mycp([ffdatadir, 'BaseFlow.ff2m'], [ffdatadir, 'MESHES/BaseFlow', designation, '.ff2m']);   
%     fffield.filename = [ffdatadir, 'MESHES/BaseFlow', designation, '.txt'];
%     myrm([ffdatadir '/BASEFLOWS/*']); % after adapt we clean the "BASEFLOWS" directory as the previous baseflows are no longer compatible
%     mycp([ffdatadir, 'BaseFlow.txt'],  [ffdatadir, 'BASEFLOWS/BaseFlow_Re',num2str(fffield.Re),'.txt']);
%     mycp([ffdatadir, 'BaseFlow.ff2m'],  [ffdatadir, 'BASEFLOWS/BaseFlow_Re',num2str(fffield.Re),'.ff2m']);
      fffield.filename = SFcore_MoveDataFiles('BaseFlow.txt',  [ 'MESHES/BaseFlow', designation, '.txt']); 
      SFcore_MoveDataFiles('BaseFlow.txt',  [ 'BASEFLOWS/BaseFlow', designation, '.txt']);
     else
         error('ERROR in SF_Adapt : baseflow recomputation failed');
     end
end


end



function [] = createMappingParamFile(MappingType,MappingParams)
% This auxiliary function creates the file with complex parameters
% There are currently 2 different cases (to be generalized someday...)

 fidlog = fopen('.stabfem_log.bash','a');
        if (fidlog>0)
            fprintf(fidlog, '#  Here a file Param_mapping.edp has been created by driver SF_SetMapping.m \n');
            fclose(fidlog);
        end

    if(isnumeric(MappingParams))  
    switch(lower(MappingType))   
            case({'jet','type1'})  
        % Mapping with 6 parameters for axisym. flow across a hole 
            fid = fopen('Param_Mapping.edp', 'w');
            fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver)\n');
            fprintf(fid, ['real ParamMapLm = ', num2str(MappingParams(1)), ' ;']);
            fprintf(fid, ['real ParamMapLA = ',  num2str(MappingParams(2)), ' ;']);
            fprintf(fid, ['real ParamMapLC = ', num2str(MappingParams(3)), ' ;']);
            fprintf(fid, ['real ParamMapGC = ',  num2str(MappingParams(4)), ' ;']);
            fprintf(fid, ['real ParamMapyA = ', num2str(MappingParams(5)), ' ;']);
            fprintf(fid, ['real ParamMapyB = ',  num2str(MappingParams(6)), ' ;']);
            fprintf(fid, ['include "MappingDef_Jet.idp" ;']);
            fclose(fid);
          case({'box','type2'})      
        % Mapping with 9 parameters for 2D flow around an object
                fid = fopen('Param_Mapping.edp', 'w');
                fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver)\n');
                fprintf(fid, ['real ParamMapCXinf = ', num2str(MappingParams(1)), ' ;']);
                fprintf(fid, ['real ParamMapXsup = ', num2str(MappingParams(2)), ' ;']);
                fprintf(fid, ['real ParamMapCYinf = ', num2str(MappingParams(3)), ' ;']);
                fprintf(fid, ['real ParamMapYsup = ', num2str(MappingParams(4)), ' ;']);
                fprintf(fid, ['real ParamMapGCx = ', num2str(MappingParams(5)), ' ;']);
                fprintf(fid, ['real ParamMapLCx = ', num2str(MappingParams(6)), ' ;']);
                fprintf(fid, ['real ParamMapGCy = ', num2str(MappingParams(7)), ' ;']);
                fprintf(fid, ['real ParamMapLCy = ', num2str(MappingParams(8)), ' ;']);
                fprintf(fid, ['include "MappingDef_Rectangle.idp" ;']);
                fclose(fid);
         case({'circle','type3'})      
        % Mapping with 3 parameters for 2D flow around an object
                fid = fopen('Param_Mapping.edp', 'w');
                fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver)\n');
                fprintf(fid, ['real ParamMapRinf = ', num2str(MappingParams(1)), ' ;']);
                fprintf(fid, ['real ParamMapGC = ', num2str(MappingParams(2)), ' ;']);
                fprintf(fid, ['real ParamMapLC = ', num2str(MappingParams(3)), ' ;']);
                fprintf(fid, ['include "MappingDef_Circle.idp" ;']);
                fclose(fid);
 
    end
    end
end