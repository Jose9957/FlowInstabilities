function mesh = SF_Mesh(meshfile, varargin)
%> Matlab/FreeFem driver for generating a mesh using a FreeFem++ program
%>
%> Usage : mesh = SF_Mesh('Mesh.edp',[opt1,val1,...])
%>
%>  Optional parameters :
%>  'Params'  :      array of real-valued parameters [Param1 Param2 ...] 
%>                   containing the parameters (reals) needed by the freefem script
%>                   and passed by standarty input
%>                   (for instance dimensions of the domain, etc...)
%>  'Options' :      string (or cell-array) containing a list of options needed by the
%>                   freefem script and handled by getARGV
%>  'cleanworkdir' : true (or 'yes') to remove any previously computed files 
%>                   from the working directory, false instead.
%>  'problemtype' :  class of problems ('2d','axi','2ccomp',....) (OBSOLETE)
%>  'symmetry' :     symmetry property : 'N' (no sym), 'S' (sym) , 'A'(antisym) 
%>                  (OBSOLETE : now handled by SF_BaseFlowls

%>
%> 'Mesh.edp' must be a FreeFem script which generates a file "mesh.msh".
%>  For the simplest cases this file will be the only needed.
%>
%>  For more elaborate cases available in the StabFem project, this function
%>  will also read the following auxiliary files (if present) : 
%>  * mesh.ff2m
%>  * mesh_connectivity.ff2m
%>  * mesh_surface.ff2m
%>
%> 
%> This file belongs to the StabFem project freely disctributed under gnu licence.
if(SF_core_getopt('storagemode')==2)
   %SF_core_arborescence('cleanall');
end


p = inputParser;
addParameter(p, 'Params', []);
addParameter(p, 'problemtype','unspecified');
addParameter(p, 'symmetry',[]);
addParameter(p, 'Options','');
addParameter(p, 'cleanworkdir',false);
parse(p, varargin{:})

ffargument = p.Results.Options;
ffargument = SF_options2str(ffargument); % transforms into a string


switch lower(p.Results.problemtype)
    case({'axixrcomplex','2dcomplex'})
        SF_core_log('w', [' USE of problemtype = ',p.Results.problemtype,' not recommended any more !']); 
end

if (p.Results.cleanworkdir)
  SF_core_arborescence('cleanall');
end
    SF_core_arborescence('cleantmpfiles');
% launches the FreeFem program
if (isempty(p.Results.Params))
 value = SF_core_freefem(meshfile,'arguments',ffargument);
else
    SF_core_log('w',' Your program uses depreciated syntax ''Params'' to pass parameters ');
    SF_core_log('w',' It is advised to switch to new method using ''Options'', and modify your Freefem solvers to detect parameters using ''getARGV''  ');
    stringparam = ' ';
    for pp = p.Results.Params
        stringparam = [stringparam, num2str(pp), '  '];
    end
     value = SF_core_freefem(meshfile,'parameters',stringparam,'arguments',ffargument);
end
if (value>0) 
    SF_core_log('e','Leaving SF_Mesh here');
    return
end



% Imports the mesh (afted displacing it to the MESH folder)
if isempty(SF_core_getopt('ffdatadir'))||strcmp(SF_core_getopt('ffdatadir'),'./')   
   SF_core_log('d',' it is advised to define a database folder.  ')
   meshfilename = 'mesh.msh';
else
   meshfilename = SFcore_MoveDataFiles('mesh.msh','MESHES');
end

mesh = SFcore_ImportMesh(meshfilename);


% Sets keyword 'symmetry' 
% (assuming symmetric flow if the mesh has a border label 6 along the x-axis)

sym = p.Results.symmetry;
%if ischar(sym)
%    SF_core_log('l',' When assigning symmetry please use now 1,0 or -1 for ''S'',''N'' or ''A'' ') 
%    if strcmp(sym,'S')
%        sym = 1;
%    elseif strcmp(sym,'A')
%        sym = -1;
%    else
%        sym = 0;
%    end
%end


if isempty(sym)
  if (ismember(6,mesh.labels)&&abs(min(mesh.points(2,:))<1e-10))
    sym = 'S';
    SF_core_log('N',' In SF_Mesh : detected a symmmetry axis (label 6) at y=0. assuming a half-mesh. symmetry property for BF calculations is set to 1. ')
  else
    sym = 'N';
    SF_core_log('NNN',' In SF_Mesh : detected no symmmetry axis ; assuming a full mesh. symmetry property for BF calculations is set to 0. ')  
  end
    SF_core_log('NNN','              If this is not what you expect please assign the value of symmetry when calling SF_Mesh ')
end

if isnumeric(sym)
    sym
    SF_core_log('e','please use ''S'',''A'' or ''N'' for symmmetrey property'); 
end

mesh.symmetry=sym;

% sets keyword 'problemtype' and writes corresponding file (OBSOLETE ???)
    mesh.problemtype = p.Results.problemtype;
    SFcore_Writeff2mFile('problemtype.ff2m',...
        'filedescription','This file was created by SF_Mesh','problemtype',mesh.problemtype);


SF_core_log('n', ['      ### INITIAL MESH CREATED WITH np = ', num2str(mesh.np), ' vertices']);



end

