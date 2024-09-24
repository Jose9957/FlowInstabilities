%> @file SOURCES_MATLAB/SF_Init.m
%> @brief Matlab/FreeFem driver for generating initial mesh and base flow
%>
%> @param[in] meshfile: Name of the FreeFem program file 
%>            (expected to be present in the working directory or in the parent directory)
%> @param[in] parameters: Parameters for the FreeFem++ script
%>             (should be compatible with the list of parameters expected by the ff program)
%> @param[out] baseflow: Generated Base Flow
%>
%> Usage in single-input mode: <code>baseflow = SF_Init('Mesh.edp')</code>
%> Usage in two-inputs mode: <code>baseflow = SF_Init('Mesh.edp',params)</code>
%>
%> 'Mesh.edp' must be a FreeFem script which generates a file "mesh.msh", a
%>  parameter file "SF_Init.ff2m", and an initial base flow
%>  "BaseFlow_init.txt" / "BaseFlow_init.ff2m"
%>
%> @author David Fabre
%> @date july 2019
%> @version 2.0
function bf = SF_Init(meshfile, varargin)

%SF_core_arborescence('clean'); % will only clean if storagemode=1

mesh = SF_Mesh(meshfile, varargin{:});
SF_core_log('n','mesh successfully created');
problemtype = mesh.problemtype;

switch lower(problemtype)
    case({'3dfreesurfacestatic','axifsstatic'})
        % in this case Baseflow.txt/ff2m have been created by the mesh generator
        SFcore_AddMESHFilenameToFF2M('FreeSurface.ff2m',mesh.filename);
        finalname = SFcore_MoveDataFiles('FreeSurface.txt','MESHES');
        bf = SFcore_ImportData(finalname);
        
    case({'axifreesurf','strainedbubble','alebucket'})    
        SFcore_AddMESHFilenameToFF2M('BaseFlow.txt',mesh.filename);
        finalname = SFcore_MoveDataFiles('BaseFlow.txt','MESHES');
        bf = SFcore_ImportData(finalname);
    case({'2d','axixr'})
        bf = SF_BaseFlow(mesh,'Re',1);
    otherwise
        SF_core_log('e','case not handled by SF_Init ; use SF_Mesh / SF_BaseFlow instead !');
        bf = [];
end

%SF_core_arborescence('cleantmpfiles'); % cleaning temporary files

SF_core_log('n', '#### SF_Init : mesh and initial "baseflow" successfully created');
end
