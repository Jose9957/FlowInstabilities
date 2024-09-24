function bs = SF_Deform(bs, varargin)
% Matlab/SF_ driver for mesh deformation  (Newton iteration)
%
% usage 1/ ffmesh = SF_Deform(ffmesh,'Volume',Volume,[...]) 
%          (cas statiques, sloshing etc...)
% usage 2/ bf = SF_Deform(bf,[...]) 
%          (cas dynamique) 
%
% this driver will lanch the "NewtonMesh" program of the coresponding
% case (ALE for instance).
%
% D. Fabre, july 2019 ; redesigned in february 2020 and Nov. 2020 
%

%ffdatadir = SF_core_getopt('ffdatadir');

%%% MANAGEMENT OF PARAMETERS (Re, Mach, Omegax, Porosity...)

%%% check which parameters are transmitted to varargin (Mode 1)
p = inputParser;

% Parameters for static problems
   addParameter(p,'gamma',1,@isnumeric); % Surface tension
   addParameter(p,'rhog',1,@isnumeric); % gravity parameter
   addParameter(p,'V',NaN,@isnumeric); % Volume. 
                                      % NB default value (volume kept) is -1 or 0 in static and dynamic problerms, consider uniformizing ! 
   addParameter(p,'Vu',NaN,@isnumeric); % Volume. Trick
   addParameter(p,'P',NaN,@isnumeric); % Pressure 
   addParameter(p,'typestart','pined',@ischar); % 
   addParameter(p,'typeend','pined',@ischar); % 
   addParameter(p,'GAMMABAR',0,@isnumeric);
   
% Parameters for dynamic problems  (generic solver)  
   addParameter(p,'nu',1,@isnumeric); % viscosity
   addParameter(p,'g',0,@isnumeric); % Weber number
   addParameter(p,'Omega',0); % rotation rate   
   addParameter(p,'S',0); % strain rate or second rotation rate 
   addParameter(p,'mode',1,@isnumeric); % mode
   
% Parameters for dynamic problems  (Strained bubble)  
   addParameter(p,'Oh',1,@isnumeric); % Ohnesorgue number
   addParameter(p,'We',0,@isnumeric); % Weber number
   addParameter(p,'Re',[]); % Reynolds number
   addParameter(p,'dS',[]); % Arclength continuation parameter

   addParameter(p,'Options',''); % argument string for tweaked mode 
   addParameter(p,'solver','default',@ischar); % to use an alternative solver
   
   addParameter(p,'DEBUG',0); % argument string for tweaked mode 
   
    
parse(p, varargin{:});


if(p.Results.GAMMABAR~=0)
    error('ERROR : GAMMABAR (rotation) not yet fully implemented... Newton_Axi_FreeSurface_Static.edp should be revised');
end

%%% Position input files

if (strcmpi(bs.datatype,'baseflow')||strcmpi(bs.datatype,'addition')||...
    strcmpi(bs.datatype,'freesurface')||strcmpi(bs.datatype,'BaseFlowSurf'))
        SF_core_log('n',['Computing base flow :  starting from guess']);
        SFcore_MoveDataFiles(bs.filename,'BaseFlow_guess.txt','cp');
        SFcore_MoveDataFiles(bs.mesh.filename,'mesh_guess.msh','cp');
        ffmesh = bs.mesh;
        
    elseif (strcmpi(bs.datatype,'mesh'))
        SF_core_log('n', ['Computing base flow : starting from guess']);
%        SF_core_system('rm','BaseFlow_guess.txt'); % To be modified soon
        SF_core_arborescence('cleantmpfiles');
        ffmesh = bs;
        SFcore_MoveDataFiles(ffmesh.filename,'mesh_guess.msh','cp');        
    else
        % imported meshes do not work
        SF_core_log('e','wrong type of argument to SF_Deform');
end

%SFcore_MoveDataFiles(ffmesh.filename,'mesh_guess.msh','cp'); 
%SFcore_MoveDataFiles(ffmesh.filename,'mesh.msh','cp'); % normally not used 

ffarguments = p.Results.Options; % for legacy cases....
switch (lower(ffmesh.problemtype))
    
    case('unspecified')
        % New generic method
        SFcore_MoveDataFiles(bs.filename,'BaseFlow_guess.txt','cp'); 
        SF_core_log('n','## Launching Newton for deformable free surface problem (generic driver)'); 
        parameterstring = '';
        ffarguments = p.Results.Options;
        ffarguments = SF_options2str(ffarguments);  % transforms into a string
        ffsolver = p.Results.solver;
        datafilename = 'BaseFlow.txt';    
        
    
    case ('axifsstatic') % New solvers using lineic meshes
        
        datafilename = 'FreeSurface.txt';
        
        if isnan(p.Results.P)&&~isnan(p.Results.V)% V-controled mode
            SF_core_log('n','## Deforming MESH For STATIC FREE SURFACE PROBLEM (V-controled)'); 
            parameterstring = ' ';
            %[' " V ',num2str(p.Results.V),' ',num2str(p.Results.gamma),...
            %    ' ',num2str(p.Results.rhog),' ',num2str(p.Results.GAMMABAR),'  ',p.Results.typestart,' ',p.Results.typeend,' " '];
            ffarguments = [ffarguments, '-typecont V -V ',num2str(p.Results.V),' -gamma ',num2str(p.Results.gamma),...
                ' -dpdz ',num2str(p.Results.rhog),' -typestart ',p.Results.typestart,' -typeend ',p.Results.typeend,' '];
            ffsolver = 'Newton_Axi_FS_Static.edp';
           
        elseif isnan(p.Results.V)&&~isnan(p.Results.P)% P-controled mode
            SF_core_log('n','## Deforming MESH For STATIC FREE SURFACE PROBLEM (P-controled)'); 
            parameterstring = ' ' ;
            %[' " P ',num2str(p.Results.P),' ',num2str(p.Results.gamma),...
            %    ' ',num2str(p.Results.rhog),' ',num2str(p.Results.GAMMABAR),' ',p.Results.typestart,' ',p.Results.typeend,' " '];
            ffarguments = [ffarguments, '-typecont P -P ',num2str(p.Results.P),' -gamma ',num2str(p.Results.gamma),...
                ' -dpdz ',num2str(p.Results.rhog),' -typestart ',p.Results.typestart,' -typeend ',p.Results.typeend,' '];
     
            ffsolver = 'Newton_Axi_FS_Static.edp';
        else
            SF_core_log('e','Error : must specify a value for either P or V'); 
        end
        
    case ('3dfreesurfacestatic')
        
        datafilename = 'FreeSurface.txt';
        
        if isnan(p.Results.P)&&~isnan(p.Results.V)% V-controled mode
            SF_core_log('n','## Deforming MESH For STATIC FREE SURFACE PROBLEM (V-controled)'); 
            parameterstring = [' " V ',num2str(p.Results.V),' ',num2str(p.Results.gamma),...
                ' ',num2str(p.Results.rhog),' ',num2str(p.Results.GAMMABAR),'  ',p.Results.typestart,' ',p.Results.typeend,' " '];
            ffsolver = 'Newton_Axi_FreeSurface_Static.edp';
           
        elseif isnan(p.Results.V)&&~isnan(p.Results.P)% P-controled mode
            SF_core_log('n','## Deforming MESH For STATIC FREE SURFACE PROBLEM (P-controled)'); 
            parameterstring = [' " P ',num2str(p.Results.P),' ',num2str(p.Results.gamma),...
                ' ',num2str(p.Results.rhog),' ',num2str(p.Results.GAMMABAR),' ',p.Results.typestart,' ',p.Results.typeend,' " '];
            ffsolver = 'Newton_Axi_FreeSurface_Static.edp';
        else
            SF_core_log('e','Error : must specify a value for either P or V'); 
        end     
        
   case ('strainedbubble')
       
      SFcore_MoveDataFiles(bs.filename,'BaseFlow.txt','cp'); % not necessary any more, to be removed
      datafilename = 'BaseFlow.txt'; 
      SFcore_MoveDataFiles([bs.mesh.filename(1:end-4),'_aux.msh'],'mesh_aux.msh','cp');
      
      
      if isempty(p.Results.dS)
        SF_core_log('n','## Deforming MESH For FREE SURFACE PROBLEM (ALE) : Oh/We mode'); 
         SF_core_log('n',['## Parameters : Oh = ',num2str(p.Results.Oh),' ; We = ',num2str(p.Results.We), ' ']);
        parameterstring = [' 4 ',num2str(p.Results.Oh),' ',num2str(p.Results.We), ' '];
        ffsolver = 'Newton_ALE_StrainedBubble_Fourier.edp';%'Newton_Axi_Surface_ALE_Fourier.edp';
      elseif ~isempty(p.Results.Re)
        SF_core_log('n','## Deforming MESH For FREE SURFACE PROBLEM (ALE) : continuation mode FIXED Re'); 
        SF_core_log('n',['## Parameters : Re = ',num2str(p.Results.Re),' ; dS = ',num2str(p.Results.dS), ' ']);
        parameterstring = [' 4 ',num2str(p.Results.Re),' ',num2str(p.Results.dS), ' '];
        ffsolver = 'Newton_ALE_StrainedBubble_Fourier_arclength_Re.edp';% to be compled 
      else
        SF_core_log('n','## Deforming MESH For FREE SURFACE PROBLEM (ALE) : continuation mode FIXED Oh'); 
        SF_core_log('n',['## Parameters : Oh = ',num2str(p.Results.Oh),' ; dS = ',num2str(p.Results.dS), ' ']);
        parameterstring = [' 4 ',num2str(p.Results.Oh),' ',num2str(p.Results.dS), ' '];
        ffsolver = 'Newton_ALE_StrainedBubble_Fourier_arclength.edp';%'Newton_Axi_Surface_ALE_Fourier_arclength.edp';
       
          

      end
   
      case ('axifreesurf')
       
      SFcore_MoveDataFiles(bs.filename,'BaseFlow_guess.txt','cp'); 
      datafilename = 'BaseFlow.txt';
     % if (p.Results.V == -1)
     %     Volume = 0;
     % else
     %     Volume = p.Results.V;
     % end
      if isnan(p.Results.P)&&~isnan(p.Results.V)% V-controled mode
        SF_core_log('n','## Deforming MESH For FREE SURFACE PROBLEM (ALE) in V-controled mode'); 
        SF_core_log('n',['## Parameters : gamma = ',num2str(p.Results.gamma),' ; nu = ',num2str(p.Results.nu), ' ; g = ',num2str(p.Results.g),...
                         ' ; Omega = ',num2str(p.Results.Omega), ' ; S/OmW = ',num2str(p.Results.S), ' ; V = ',num2str(p.Results.V), ]);
        parameterstring = ['V ',num2str(p.Results.V), ' ',num2str(p.Results.gamma),' ',num2str(p.Results.nu),' ',num2str(p.Results.g),...
                         ' ',num2str(p.Results.Omega),' ',num2str(p.Results.S) ];
        ffsolver = 'Newton_3dAxi_ALE_Generic.edp';
      elseif isnan(p.Results.P)&&isnan(p.Results.V)&&~isnan(p.Results.Vu)% V-controled mode
        SF_core_log('n','## Deforming MESH For FREE SURFACE PROBLEM (ALE) in Vu-controled mode'); 
        SF_core_log('n',['## Parameters : gamma = ',num2str(p.Results.gamma),' ; nu = ',num2str(p.Results.nu), ' ; g = ',num2str(p.Results.g),...
                         ' ; Omega = ',num2str(p.Results.Omega), ' ; S/OmW = ',num2str(p.Results.S), ' ; V = ',num2str(p.Results.V), ]);
        parameterstring = ['Vu ',num2str(p.Results.Vu), ' ',num2str(p.Results.gamma),' ',num2str(p.Results.nu),' ',num2str(p.Results.g),...
                         ' ',num2str(p.Results.Omega),' ',num2str(p.Results.S) ];
        ffsolver = 'Newton_3dAxi_ALE_Generic.edp';  
      elseif isnan(p.Results.V)&&~isnan(p.Results.P)% P-controled mode
        SF_core_log('n','## Deforming MESH For FREE SURFACE PROBLEM (ALE) in P-controled mode'); 
        SF_core_log('n',['## Parameters : gamma = ',num2str(p.Results.gamma),' ; nu = ',num2str(p.Results.nu), ' ; g = ',num2str(p.Results.g),...
                         ' ; Omega = ',num2str(p.Results.Omega), ' ; S/OmW = ',num2str(p.Results.S), ' ; P = ',num2str(p.Results.P), ]);
        parameterstring = ['P ',num2str(p.Results.P), ' ',num2str(p.Results.gamma),' ',num2str(p.Results.nu),' ',num2str(p.Results.g),...
                         ' ',num2str(p.Results.Omega),' ',num2str(p.Results.S) ];
        ffsolver = 'Newton_3dAxi_ALE_Generic.edp';
       else
            SF_core_log('e','Error : must specify a value for either P or V'); 
      end 
          
   case ('alebucket')
       
      SFcore_MoveDataFiles(bs.filename,'BaseFlow_guess.txt','cp'); 
      datafilename = 'BaseFlow.txt';
      if (p.Results.V == -1)
          Volume = 0;
      else
          Volume = p.Results.V;
      end
        SF_core_log('n','## Deforming MESH For FREE SURFACE PROBLEM (ALE-BUCKET)'); 
        SF_core_log('n',['## Parameters : gamma = ',num2str(p.Results.gamma),' ; nu = ',num2str(p.Results.nu), ' ; g = ',num2str(p.Results.g),...
                         ' ; Omega = ',num2str(p.Results.Omega), ' ; S/OmW = ',num2str(p.Results.S), ' ; V = ',num2str(p.Results.V), ]);
        parameterstring = [num2str(p.Results.mode),' ',num2str(p.Results.gamma),' ',num2str(p.Results.nu),' ',num2str(p.Results.g),...
                         ' ',num2str(p.Results.Omega),' ',num2str(p.Results.S),' ' ,num2str(Volume) ];
        ffsolver = 'Newton_3dAxi_ALE_Thorbucket.edp';       
   otherwise
        error('case not implemented in SF_Mesh_Deform')
end


%p.Results.solver

if(strcmp(p.Results.solver,'default'))
    SF_core_log('w',['      ### USING STANDARD StabFem Solver ',ffsolver]);        
else
        ffsolver = p.Results.solver; 
        SF_core_log('w',['      ### USING CUSTOM StabFem Solver ',ffsolver]);  
end

value = SF_core_freefem(ffsolver,'parameters',parameterstring,'arguments',ffarguments);


if(value ~= 0)
  SF_core_log('w','Newton iteration diverged !');
  bs.iter = -1;
  return
end

%    SF_core_arborescence('clean'); % will only clean if storagemode=1 % TO BE VERIFIED

% Copying new mesh files to database
    newname = SFcore_MoveDataFiles('mesh.msh','MESHES','cp');
    ffmeshNew = SFcore_ImportMesh(newname);
    ffmeshNew.problemtype = ffmesh.problemtype;
    mesh = ffmeshNew; 
    
% Copying new baseflow files to database    
    SFcore_AddMESHFilenameToFF2M(datafilename,mesh.filename);
    finalname = SFcore_MoveDataFiles(datafilename,'MESHBF','cp'); 
    bs = SFcore_ImportData(finalname);
    bs.mesh.problemtype = ffmesh.problemtype; % should not be necessary but bug detected, to be fixed
    

SF_core_log('n', '#### SF_Mesh_Deform : NEW MESH CREATED');
end
