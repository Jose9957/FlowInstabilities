%> @file SOURCES_MATLAB/SF_Adapt.m
%> @brief Matlab driver for Mesh Adaptation
%> 
%> Usage : 
%> 1/ using Mesh + Datasets (for linear problems without baseflows, e.g. sloshing, acoustics...)
%> [mesh [,flow1,flow2,...] ] = SF_Adapt(mesh,flow1 [,flow2,...] [,'opt1','val1']) 
%> 
%> 2/ using only Datasets (recommended mode ; NB mesh is a field of the dataset objects)
%> [flow1 [,flow2,...] ] = SF_Adapt(flow1 [,flow2,...] [,'opt1','val1']) 
%>
%> @param[in] (optional) mesh : mesh-object (only when using in mesh-associated mode)
%> @param[in] flow1 : flow provided for mesh adaptation.
%> @param[in] (optional) flow2, flow3, etc... 
%>             additional flows for adaptation to multiple flows (max number currently 3) 
%>
%> OPTIONS :
%> @param[in] Hmax : Maximum size of grid step
%> @param[in] Hmin : Minimum size of drid step
%> @param[in] Ratio : Size ratio between adjacent elements (???)
%> @param[in] Nbvx : Max Total number of vertices
%> @param[in] InterpError : Interpolation error of the projected field onto the new mesh
%> @param[in] rr : (???)
%> @param[in] Splitin2 : (bool) Split every element in two
%> @param[in] Splitbedge : (bool) Split every edge in two
%> @param[in] Thetamax : (float) Minimum angle of the triangular element.
%> @param[in] keepbackvertices : (bool) Keeps previous vertices.
%> @param[in] anisomax : (int) Level of anisotropy (infinity large anisotropy).
%> @param[in] nbjacoby : (int) number of iterations in a smoothing procedure during the metric construction, 
%>							   (0 means no smoothing, 6 is the default)
%> @param[in] recompute : (bool) Recompute base flow after adaptation.
%> @param[in] Store : folder where to store projected fields (see note below)
%> @param[in] StoreMesh : folder where to store new mesh (default : 'MESHES/')
%>
%> @param[out] flow1: flow structure reprojected on adapted mesh
%> @param[out] flow2; ... if asked, eigenmode recomputed on adapted mesh
%>
%> IMPORTANT NOTE 1 : DATABASE MANAGEMENT.
%>  - New mesh will be stored in folder "MESHES", unless stated differently by option 'StoreMesh'
%>  - If using mode 2 (only datasets) AND if flow1 is of either type "BaseFlow" or "FreeSurface", 
%>    the projection of this dataset will be stored in folder "MESHES", 
%>    unless stated differently by option 'StoreMesh'
%>  - Other types of datasets (flow2, etc..., as well as flow1 if not "BaseFlow"  or "FreeSurface") 
%>    will be stored in folder "MISC" , unless stated differently by option 'StoreMesh'
%>
%> IMPORTANT NOTE 2 : Recomputation of baseflows for "problemtype-driven" method  
%>                    (legacy method, not recommended to use this any more)
%>     If using mode 2 (only datasets) AND if flow1 is of type "BaseFlow" 
%>     AND if a "problemtype" has been defined when creating the mesh,
%>     then baseflow is recomputed after flow adatpation. Additional flows are simply 
%>     reprojected on new mesh, not recomputed.
%>     In this case the recomputed baseflows will be stored in folder "BASEFLOWS".
%>  To disable this (potentially dangerous) method use option 'recompute',false
%>                  
%>
%> @author David Fabre & J. Sierra, redesigned in nov. 2018
%> @version 2.1
%> @date 02/07/2017 Release of version 2.1
%>
%> History :
%> Rationalisation in feb. 2019 but remains to be simplified !!
%> New rationalization in oct. 2020.

function varargout = SF_Adapt(varargin)


varargout = {}; % introduced to avoid a bug at line 227 in some cases (to be rationalized)

SF_core_log('d', '### ENTERING SF_ADAPT')

% managament of optional parameters
% NB here the parser had to be customized because input parameter number 2
% is optional and is a structure ! we should find a better way in future

%%% sorting the input parameters into fields and options.
nfields=0;
for i=1:nargin
if(isstruct(varargin{i}))
    nfields=nfields+1;
end
end
vararginopt = {varargin{nfields+1:end}};

% Special management if first argument is a mesh
if(strcmpi(varargin{1}.datatype,'mesh'))
    vararginfields = {varargin{2:nfields}};
    nfields = nfields-1;
    ffmesh = varargin{1};
    SF_core_log('l',' Warning : please avoid to use SF_Adapt with a mesh as first argument');
else
    vararginfields = {varargin{1:nfields}};
    ffmesh = varargin{1}.mesh;
end



% creating an array of structures "flowtoadapt"
% here we want to do 
%   flowtoadapt = [varargin{1:nfields}] 
% but this does not work because the fields may have dissimilar structures !
% below is a WORKAROUND found there 
% https://fr.mathworks.com/matlabcentral/answers/152580-converting-a-cell-array-of-dissimilar-structs-to-an-array-of-structs
uniqueFields = unique(char(cellfun(@(x)char(fieldnames(x)),{vararginfields{1:nfields}},'UniformOutput',false)),'rows');
for k=1:nfields
     for u=1:size(uniqueFields,1)
         fieldName = strtrim(uniqueFields(u,:));
         if length(vararginfields{k})>1
             SF_core_log('e','Arguments to SF_Adapt must be handles not arrays');
         end
         if ~isfield(vararginfields{k}, fieldName)
             vararginfields{k}.(fieldName) = [];
         end
     end
end
flowforadapt = [vararginfields{1:nfields}];
% END WORKAROUND 



%%% Interpreting parameters
p = inputParser;
%    addRequired(p,'baseflow');
%    addOptional(p,'eigenmode',0);
addParameter(p, 'Hmax', -1); % default value =-1 -> automatic determination
addParameter(p, 'Hmin', -1); % idem
addParameter(p, 'Ratio', 10.);
addParameter(p, 'Nbvx', 1e5);
addParameter(p, 'InterpError', 1e-2);
addParameter(p, 'rr', 0.95);
addParameter(p, 'Splitin2', false);
addParameter(p, 'Splitbedge', false,@islogical);
addParameter(p, 'Thetamax', 10);
addParameter(p, 'keepbackvertices', false,@islogical);
addParameter(p, 'anisomax', 10); 
addParameter(p, 'nbjacoby', 6); 
addParameter(p, 'Split', false); 
addParameter(p, 'isofield', true); 

addParameter(p, 'recompute',true,@islogical);
addParameter(p, 'Store', 'default'); 
addParameter(p, 'StoreMesh', 'MESHES'); 
addParameter(p, 'ncores', 1);



addParameter(p,'Options','');

parse(p, vararginopt{:});

%%% Writing parameter file for Adapmesh
writeParamFile('Param_Adaptmesh.idp',p.Results); %% see function defined at bottom


%%% constructing option string and positioning files
optionstring = [' ', num2str(nfields), ' '];
SFcore_MoveDataFiles(ffmesh.filename,'mesh.msh','cp');
for i=1:nfields
     SFcore_MoveDataFiles(flowforadapt(i).filename, ['FlowFieldToAdapt',num2str(i),'.txt'],'cp');
    [~,storagemode,nscalars] = fileparts(flowforadapt(i).datastoragemode); % this is to extract two parts of datastoragemode, e.g. 
    if(strcmp(nscalars,''))
        nscalars = '0';
    else
        nscalars = nscalars(2:end); %to remove the dot
    end
    optionstring = [optionstring, ' ', storagemode, ' ' , nscalars , ' '];
end
if ~isempty(p.Results.Options)
    optionstring = [ optionstring ,' ',p.Results.Options];
end


 
%%% Invoking FreeFem++ program AdaptMesh.edp   

if ~p.Results.Split
    SF_core_freefem('AdaptMesh.edp','parameters',optionstring,'arguments',p.Results.Options);      
else
    SF_core_freefem('AdaptMesh.edp','parameters',optionstring,'arguments','-nsplit 2'); 
end

%%% for ALE cases : must produce a secondary file for mesh inside the bubble (to be moved elsewhere)
if strcmp(ffmesh.problemtype,'strainedbubble')
     SF_core_freefem('CreateInnerMeshForALE.edp','parameters','postadapt');
end



%%% OUTPUT    

% store mesh in MESHES folder (unless stated differently)
if isempty(SF_core_getopt('ffdatadir'))||strcmp(SF_core_getopt('ffdatadir'),'./')   
   SF_core_log('w',' When using SF_Adapd it is advised to define a database folder.  ')
   meshfilename = 'mesh_adapt.msh';   
else
   meshfilename = SFcore_MoveDataFiles('mesh_adapt.msh',p.Results.StoreMesh);
end

newmesh = SFcore_ImportMesh(meshfilename,'problemtype',ffmesh.problemtype);

SF_core_log('n',['SF_Adapt : created new mesh ; np = ',num2str(newmesh.np), ' vertices ']);

if(strcmpi(varargin{1}.datatype,'mesh')) % UGLY FIX TO BE DONE BETTER
    nargoutF=nargout-1;
else
    nargoutF=nargout;
end

for i = 1:nargoutF

   SF_core_syscommand('cp',[SF_core_getopt('ffdatadir'),'FlowFieldToAdapt',num2str(i),'.ff2m'],...
                           [SF_core_getopt('ffdatadir'),'FlowFieldAdapted',num2str(i),'.ff2m']);
   %NB here we copy the .ff2m file but the content may be false ! as a consequence only metadata should be imported               

   SFcore_AddMESHFilenameToFF2M(['FlowFieldAdapted',num2str(i),'.txt'],newmesh.filename); % actually .ff2m not .txt ??
        
    if (i==1)&&~strcmp(ffmesh.problemtype,'unspecified')&&(strcmpi(varargin{1}.datatype,'baseflow')||strcmpi(varargin{1}.datatype,'freesurface'))
        if strcmp(p.Results.Store,'default')
           SF_core_log('l',' Projected baseflow copied in folder "MESHES" (legacy method)');
           finalname = SFcore_MoveDataFiles('FlowFieldAdapted1.txt','MESHES/','cp');
        else
           finalname = SFcore_MoveDataFiles('FlowFieldAdapted1.txt',p.Results.Store,'cp');    
        end
    else
        if strcmp(p.Results.Store,'default')
            finalname = SFcore_MoveDataFiles(['FlowFieldAdapted',num2str(i),'.txt'],'MISC/','cp'); 
        else 
            finalname = SFcore_MoveDataFiles(['FlowFieldAdapted',num2str(i),'.txt'],p.Results.Store,'cp');
        end
    end
    
    varargout{i} = SFcore_ImportData(newmesh,finalname,'metadataandtxt');
    varargout{i}.iter = 0;
    
    for u=1:size(uniqueFields,1)
         fieldName = strtrim(uniqueFields(u,:));
         if isfield(varargout{i},fieldName)&&isempty(varargout{i}.(fieldName)) % ???
             SF_core_log('w',['Removing field ', fieldName ' in post-adapt structure ']);
             varargout{i} = rmfield(varargout{i},fieldName);
         end
    end
end



%%% if first field is a base flow we have to recompute it ! (only for "old-style" problems controled by problem type, and not free surface ones)    
% SECTION TO BE RATIONALIZED
% if strcmpi(varargin{1}.datatype,'baseflow')
%  if p.Results.recompute&&~strcmp(ffmesh.problemtype,'unspecified')
%   if (~strcmp(ffmesh.problemtype,'axifreesurf')&&~strcmp(ffmesh.problemtype,'strainedbubble'))%&&~contains(lower(ffmesh.problemtype),'kaptsov'))
%     SF_core_log('n',' SF_Adapt : recomputing base flow on adapted mesh');
%     
%     % patch new interface
%     if isfield(varargin{1},'Symmetry') 
%         varargout{1}.Symmetry = varargin{1}.Symmetry;
%     end
%     if isfield(varargin{1},'solver') 
%         varargout{1}.solver = varargin{1}.solver;
%     end
%     % end patch    
%     
%     baseflowNew = SF_BaseFlow(varargout{1}, 'type', 'POSTADAPT','ncores',p.Results.ncores); 
%      if (baseflowNew.iter >= 0)
%      %  Newton successful : Store adapted mesh/base flow in directory  "MESHES" -> NOT ANY MORE
%      % finalname = SFcore_MoveDataFiles(baseflowNew.filename,'MESHES','cp');
%     % baseflowNew.filename = finalname;%[ffdatadir, 'MESHES/BaseFlow',designation, '.txt'];
%     % varargout{1} = baseflowNew; 
% %     SF_core_arborescence('clean'); % will clean only if SF_core_getopt('storagemode')=2    
% %     finalname = SFcore_MoveDataFiles(finalname,'BASEFLOWS','cp');
%      varargout{1} = baseflowNew; 
%      else
%          SF_core_log('w','ERROR in SF_Adapt : baseflow recomputation failed');
%          varargout{1}.iter = -1; % should put this as well in the file
%          finalname = SFcore_MoveDataFiles(varargout{1}.filename,'MESHES','cp');
%      end
%   end
%  else
%  %   varargout{1}.iter = 0; % should put this as well in the file
%  %   varargout{1}
%     if ~strcmp(ffmesh.problemtype,'unspecified')
%        finalname = SFcore_MoveDataFiles(varargout{1}.filename,'MESHBF','cp');
%     end
%     SF_core_log('nn',' The adapted field has been projected but not recomputed ! please make sure to run again SF_Launch or SF_Baselow before using it');      
%   end
% elseif strcmp(varargin{1}.datatype,'BaseFlowSurf')
%     finalname = SFcore_MoveDataFiles(varargout{1}.filename,'MESHBF','cp');
%     SF_core_log('nn',' The adapted field has been projected but not recomputed ! please make sure to run again SF_Deform before using it');      
% else    
%     SF_core_log('nn',' Adapt mesh without base flow');
% end



% if first input was a mesh, then first output will be the mesh
if(strcmpi(varargin{1}.datatype,'mesh'))  
    if(isfield(ffmesh,'gamma'))
        newmesh.gamma = ffmesh.gamma;
    end
     if(isfield(ffmesh,'rhog'))
        newmesh.rhog = ffmesh.rhog;
     end
    varargout  = {newmesh varargout{:}}; % leave it this way even if not elegant ! varargout may be empty
end
SF_core_log('nnn','IN SF_Adapt : should we clean the Eigenmodes.* ?')   

% eventually clean working directory from temporary files
SF_core_arborescence('cleantmpfiles')
 
SF_core_log('d', '### LEAVING SF_ADAPT')

end






function [] = writeParamFile(filename,p)
fid = fopen(filename, 'w');
fprintf(fid, '// Parameters for adaptmesh (file generated by matlab driver)\n');
fprintf(fid, ['real Hmax = ', num2str(p.Hmax), ' ;\n']);
fprintf(fid, ['real Hmin = ', num2str(p.Hmin), ' ;\n']);
fprintf(fid, ['real Ratio = ', num2str(p.Ratio), ' ;\n']);
fprintf(fid, ['real error = ', num2str(p.InterpError), ' ;\n']);
fprintf(fid, ['real rr = ', num2str(p.rr), ' ;\n']);
fprintf(fid, ['int Nbvx = ',num2str(p.Nbvx), ' ; \n']);        
fprintf(fid, ['real Thetamax = ', num2str(p.Thetamax),'; \n']);
fprintf(fid, ['real anisomax = ', num2str(p.anisomax),'; \n']);
fprintf(fid, ['real nbjacoby = ', num2str(p.nbjacoby),'; \n']);

if(p.Splitbedge==0)
  fprintf(fid, 'bool Splitpbedge= false; \n');
else
  fprintf(fid, 'bool Splitpbedge= true; \n');
end 
if (p.Splitin2 == 0)
    fprintf(fid, 'bool Splitin2 = false ; \n');
else
    fprintf(fid, 'bool Splitin2 = true ; \n' );
end

if p.keepbackvertices
    fprintf(fid, 'bool Keepbackvertices = true ; \n');
else
    fprintf(fid, 'bool Keepbackvertices = false ; \n' );
end
fprintf(fid, 'real Verbosity    = 1; \n');

if (p.isofield == 0)
    fprintf(fid, 'bool isofield = false ; \n');
else
    fprintf(fid, 'bool isofield = true ; \n' );
end


fclose(fid);

 fidlog = fopen('.stabfem_log.bash','a');
        if (fidlog>0)
            fprintf(fidlog, ['#  Here a file  ', filename, ' has been created by driver SF_Adapt \n'] );
            fclose(fidlog);
        end

end


