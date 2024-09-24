%> @file SOURCES_MATLAB/SF_BaseFlow.m
%> @brief StabFem wrapper for Base flow calculation (Newton iteration)
%>
%> @param[in] baseflow: baseflow guess to initialise NEwton iterations
%> @param[in] varargin: list of parameters and associated values
%> @param[out] baseflow: baseflow solved by Newton iterations
%>
%> usage: 
%> 1/ baseflow = SF_BaseFlow(baseflow,['Param1',Value1,...])
%> 2/ baseflow = SF_BaseFlow(ffmesh,['Param1',Value1,...])
%>
%> in mode 1 (first argument is a previously computed baseflow) 
%             this previous baseflow will be used to initialmize the Newton iter.  
%> in mode 2 (first argument is a mesh) 
%>              No initial condition is prescribed. The solver will use a default one 
%>             unless a macro "DefaultGuessForNewton" is defined in your Macro_StabFem.idp  
%>
%> This wrapper will launch the Newton FreeFem++ program of the corresponding
%>  case. Nota Bene: if baseflow was already created, it is simply copied from
%>  the "BASEFLOW" directory (unless specified otherwise by parameter 'Type').
%>
%> List of valid parameters:
%>
%>   - solver :    Name ('###.edp') of the FreeFem++ solver to be used for the calculation. 
%>                 If not specified the solver specified at a previous call
%>                 will be used.
%>                 Alternatively, if no solver is defined but a "problemtype"
%>                 has been defined when creating the mesh, a default solver
%>                 relevant to the "problemtype" class of problems will be used.
%>                 (Legacy mode, not recommended any more).
%>   - Options :  List of options to be transmitted to FreeFem program as list of arguments 
%>                  (Either a cell-array of descriptor-value pairs, a structure, 
%>                  or directly a string like '-Param1 value1 -Param2 value 2'
%>   - Include :   A cell-array of strings to be included in the prologue of
%>                   the FreeFem program )
%>   - ncores :    Number of cores (for parallel computations)
%>
%> List of options from previous method of parameters management (with keywork problemtype)
%> (not recommended to use any more ; all parameters should now be in the 'Options' cell-array
%>
%>   - Re          Reynolds number
%>   - Ma          Mach number (for compressible cases)
%>   - Omegax      Rotation rate (for swirling axisymetric or 2D body)
%>   - Darcy       Darcy number (for cases with porous body)
%>   - Porosity    Porosity (for cases with porous body)
%>   - Ra          Rayleigh number (for Boussinesq case)
%>   - Pr          Prandtl number  (for Boussinesq case) 
%>   - (nonexhaustive list... you can add you own parameters)
%>
%>   - Type (OBSOLETE)
%>      - 'NEW' to force new computation and discard importation from a
%>        a file present in database and fitting parameters (default).  
%>      - 'DataBase' : if exists in the database (with current mesh) import it
%>      - 'POSTADAPT' for recomputing baseflow after mesh adaptation ;
%>      - 'PREV' if connection was lost (obsolete ?)
%>
%>
%> SF IMPLEMENTATION:
%> In legacy mode, depending on "problemtype", this wrapper will select and launch one of the
%>  following FreeFem++ solvers:
%>       'Newton_Axi.edp'
%>       'Newton_AxiSWIRL.edp'
%>       'Newton_2D.edp'
%>       'Newton_2D_Comp.edp'
%>         (... maybe many others...)
%>
%> Nota Bene: if for some reason the mesh/baseflow compatibility was lost, use
%>  SF_BaseFlow(baseflow,'Re',Re,'type','PREV') to reconstruct the structure and
%>  relocate files correctly. (PROBABLY OBSOLETE).
%>
%> @author David Fabre
%> @date 2017-2020
%> @copyright GNU Public License

function baseflowNEW = SF_BaseFlow(baseflow, varargin)

SF_core_log('d', '### ENTERING FUNCTION SF_BaseFlow ');

% MANAGEMENT OF PARAMETERS (Re, Mach, Omegax, Porosity...)
% Explanation
% (Mode 1) if parameters are transmitted to the function we use these ones.
%      (for instance baseflow = SF_BaseFlow(baseflow1,'Re',10)
% (Mode 2) if no parameters are passed and if the field exists in the previous
% baseflow, we take these values
%      (for instance SF_BaseFlow(bf) is equivalent to SF_Baseflow(bf,'Re',bf.Re) )
% (Mode 3) if no previous value we will define default values set in the next lines.

%persistent previoussolver;
if SF_core_isopt('BFSolver')
    previoussolver = SF_core_getopt('BFSolver');
else
    previoussolver=[];
end

persistent previousncores;

 if isfield(baseflow,'iter')&&baseflow.iter<0
     SF_core_log('w' ,' baseflow.iter < 0 ! it seems your previous baseflow computation diverged !');
 elseif isfield(baseflow,'iter')&&baseflow.iter==0
     SF_core_log('d' ,' baseflow.iter = 0 ! it seems your guess baseflow was projected after mesh adaptation !');
 end

p = inputParser;

global TweakedParameters;
TweakedParameters.list = {};
SFcore_addParameter(p, baseflow,'Re', 1, @isnumeric); % Reynolds
SFcore_addParameter(p, baseflow,'Mach', 0.01, @isnumeric); % Mach
SFcore_addParameter(p, baseflow,'Omegax', 0, @isnumeric); % Rotation rate (argument parameter)
SFcore_addParameter(p, baseflow,'alpha', 0, @isnumeric); % Incidence angle (argument parameter)

SFcore_addParameter(p, baseflow,'U1', 1); % Velocity scale 1 (for instance max of first jet)
SFcore_addParameter(p, baseflow,'U2', 1); % Velocity scale 2 (for instance max of second jet)
SFcore_addParameter(p, baseflow,'bctype', 0); % Velocity scale 2 (for instance max of second jet)

SFcore_addParameter(p, baseflow,'Darcy',1 , @isnumeric); % For porous body
SFcore_addParameter(p, baseflow,'Porosity', 0.95, @isnumeric); % For porous body too

SFcore_addParameter(p, baseflow,'Cu', 0, @isnumeric); % For rheology
SFcore_addParameter(p, baseflow,'AspectRatio', 0, @isnumeric); % For rheology
SFcore_addParameter(p, baseflow,'nRheo', 0, @isnumeric); % For rheology

SFcore_addParameter(p, baseflow, 'Ra', 1705,  @isnumeric); % for Boussinesq
SFcore_addParameter(p, baseflow, 'Pr', 10,    @isnumeric); % for Boussinesq
SFcore_addParameter(p, baseflow, 'Qmag', 0,   @isnumeric); % for Boussinesq

SFcore_addParameter(p, baseflow, 'Eac', 1,   @isnumeric); % for Kaptsov
SFcore_addParameter(p, baseflow, 'Vc', 0,   @isnumeric); % for Kaptsov
SFcore_addParameter(p, baseflow, 'Pe', 1,   @isnumeric); % for Kaptsov As WELL
SFcore_addParameter(p, baseflow, 'epslambda', -1,   @isnumeric); % for Kapsov

addParameter(p, 'type', 'NEW', @ischar); % for special mode


addParameter(p, 'MappingDef', 'none'); % complex Mapping type (OBSOLETE) 
addParameter(p, 'MappingParams', 'default'); % Array of parameters for the cases involving mapping

SFcore_addParameter(p,baseflow,'solver','default',@ischar); % to use an alternative solver
addParameter(p,'Options','');
addParameter(p, 'ncores', 0, @isnumeric); % number of cores to launch in parallel
addParameter(p,'ffbin','default',@ischar); % to use an alternative solver

SFcore_addParameter(p, baseflow,'Symmetry','N'); % Reynolds

addParameter(p, 'store', 'BASEFLOWS', @ischar); % for special mode

addParameter(p, 'Include','');

parse(p, varargin{:});

% Main parameters (usually transmitted by standart input to solver)
Re = p.Results.Re;
Ma = p.Results.Mach;


% Auxiliary and case-dependant parameters (usually transmitted by getARGV to solver) 
ffargument = p.Results.Options;

%if (p.Results.Omegax~=0.)
%    ffargument = [ ffargument, ' -Omegax ', num2str(p.Results.Omegax)];
%end
%if (p.Results.alpha~=0.)
%    ffargument = [ ffargument, ' -alpha ', num2str(p.Results.alpha)];
%end
%if ~isempty(p.Results.U1)
%    ffargument = [ ffargument, ' -U1 ', num2str(p.Results.U1)];
%end
%if ~isempty(p.Results.U2)
%    ffargument = [ ffargument, ' -U2 ', num2str(p.Results.U2)];
%end
%if ~isempty(p.Results.bctype)
%    ffargument = [ ffargument, ' -bctype ', num2str(p.Results.bctype)];
%end
    
%Omegax = p.Results.Omegax;
%Darcy = p.Results.Darcy;
%Porosity = p.Results.Porosity;
%ncores = p.Results.ncores; % By now only for the 2D compressible


%%% Position input files
    if (strcmpi(baseflow.datatype,'baseflow')||strcmpi(baseflow.datatype,'addition'))
        SF_core_log('nn',['Computing base flow :  starting from guess']);
        SFcore_MoveDataFiles(baseflow.filename,'BaseFlow_guess.txt','cp');
        SFcore_MoveDataFiles(baseflow.mesh.filename,'mesh.msh','cp');
        mesh = baseflow.mesh;
        problemtype = baseflow.mesh.problemtype;
        
    elseif (strcmpi(baseflow.datatype,'mesh'))
        SF_core_log('nn', ['Computing base flow : starting from mesh']);
        mymyrm('BaseFlow_guess.txt'); % To be modified soon
        problemtype = baseflow.problemtype;
        mesh = baseflow;
        SFcore_MoveDataFiles(mesh.filename,'mesh.msh','cp');
        
    else
 %       % imported meshes do not work
 %       error('wrong type of argument to SF_BaseFlow')
        SF_core_log('w',['Computing base flow :  starting field is not a regular baseflow']);
        SF_core_log('w',['Trying to continue but it is advised that you use SF_Launch instead of SF_BaseFlow']);
        SF_core_log('l','Legacy issue here');
        SFcore_MoveDataFiles(baseflow.filename,'BaseFlow_guess.txt','cp');
        SFcore_MoveDataFiles(baseflow.mesh.filename,'mesh.msh','cp');
        mesh = baseflow.mesh;
        problemtype = baseflow.mesh.problemtype;
 
    end
    

%if contains(lower(problemtype),'2d')
%    ffargument = [ ffargument, ' -sym ', num2str(mesh.symmetry)];
%end    

%%% SELECTION OF THE SOLVER TO BE USED DEPENDING ON THE CASE

ffbin = 'default';  % will use FreeFem++-mpi ; specified something else if required
BFfilename = ''; % this was previously used to put the metadata in the filename

if p.Results.ncores==0
    if isempty(previousncores)
        ncores = 1;
    else
        ncores = previousncores;
    end
else
    ncores = p.Results.ncores;
end
previousncores = ncores;
SF_core_log('n',['Working with ',num2str(ncores),' cores']);

switch (lower(problemtype))
    
    case ('unspecified')
        % This is the new generic interface, treating all parameters through getARGV
        ffparams = ' ' ;
        if ischar(ffargument)
            ffargument2 = SF_CreateArgumentString(p,TweakedParameters); % assembly from parameters
            ffargument = [ffargument2 ffargument];
        else
            ffargument = SF_options2str(ffargument); % transforms into a string
        end
        ffsolver = p.Results.solver;
        if strcmp(ffsolver,'default')
            if isempty(previoussolver)
               SF_core_log('e','ERROR : You must either specify a solver when calling SF_BaseFlow or specify a problemtype when creating mesh');
            else
                SF_core_log('nn',['Using previously defined solver ',previoussolver]);
                ffsolver = previoussolver;
            end
        else
             SF_core_log('nn',['## Entering SF_BaseFlow : using generic interface for Newton solver ',ffsolver]); 
             previoussolver = ffsolver;
             if isempty(SF_core_getopt('BFSolver'))
                SF_core_setopt('BFSolver',previoussolver);
             end
        end 
      case ({'2dstokes'})
        SF_core_log('nn', '## Entering SF_BaseFlow (2D INCOMPRESSIBLE)');
        ffparams = '';
        ffargument = [ffargument, ' -Re ',num2str(Re), ' -alpha ', num2str(p.Results.alpha), ' -Omegax ', num2str(p.Results.Omegax), ' -Symmetry ' , mesh.symmetry];
        ffsolver = 'Newton_Stokes_2D.edp';       
     case ({'2d','2dmobile'})
        SF_core_log('nn', '## Entering SF_BaseFlow (2D INCOMPRESSIBLE)');
       
       if(ncores == 1)
            ffparams = '';
            ffargument = [ffargument, ' -Re ',num2str(Re), ' -alpha ', num2str(p.Results.alpha), ' -Omegax ', num2str(p.Results.Omegax), ' -Symmetry ' , mesh.symmetry];
            ffsolver = 'Newton_2D.edp';      
       else
            ffparams =' ';
            ffargument = [' -Re ', num2str(Re), ' ',ffargument];
            ffbin = 'ff-mpirun';
            ffsolver = 'Newton_2D_Parallel.edp';
        end

     case ({'2d_2dof'})
        SF_core_log('nn', '## Entering SF_BaseFlow (2D INCOMPRESSIBLE with 2 DOF)');
        ffparams = '';
        ffargument = [ffargument, ' -Re ',num2str(Re), ' -alpha ', num2str(p.Results.alpha), ' -Omegax ', num2str(p.Results.Omegax), ' -Symmetry ' , mesh.symmetry];
        ffsolver = 'Newton_2D_2DOF.edp';      


    case ('2dboussinesq')
        SF_core_log('nn', '## Entering SF_BaseFlow (2D Boussinesq)');
        ffparams = [ num2str(p.Results.Ra), ' ', num2str(p.Results.Pr), ' ' ,num2str(p.Results.Qmag)];
        ffsolver = 'Newton_2D_Boussinesq.edp';

    case ('2drheology')
        SF_core_log('nn', '## Entering SF_BaseFlow (2D INCOMPRESSIBLE) with rheology');
        ffparams = [ num2str(Re), ' ', num2str(p.Results.Omegax), ' ' , num2str(p.Results.AspectRatio), ' ' , num2str(p.Results.Cu), ' ' , num2str(p.Results.nRheo), ' ' , mesh.symmetry];
        ffsolver = 'Newton_2D_Rheology.edp';
        BFfilename = [ 'BaseFlow_Re', num2str(Re), '_Cu', num2str(p.Results.Cu), '_AspectRatio', num2str(p.Results.AspectRatio), '_nRheo', num2str(p.Results.nRheo)];
        
    case ('axixr') % Newton calculation for axisymmetric base flow
        SF_core_log('nn', '## Entering SF_BaseFlow (axisymmetric case)');
       ffparams =' ';
       ffargument = [' -Re ', num2str(Re), ' ',ffargument];
       if(ncores == 1)
            ffbin = 'FreeFem++-mpi';
            ffsolver = 'Newton_Axi.edp';
        else
            ffbin = 'ff-mpirun';
            ffsolver = 'Newton_Axi_Parallel.edp';
        end
       
        
    case ('axixrcomplex') % Newton calculation for axisymmetric base flow WITH COMPLEX MAPPING
        
        SF_core_log('nn', '## Entering SF_BaseFlow (axisymmetric case)');
        %%% Writing parameter file for Adapmesh
        if ~strcmp(p.Results.MappingDef,'none')
            SF_core_log('w','Using COMPLEX BASE FLOW Newton_Axi_COMPLEX.edp (not recommended any more)'); 
            SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams);
            ffsolver = 'Newton_Axi_COMPLEX.edp';
        else
            SF_core_log('nn','Using regular REAL base flow with solver Newton_Axi.edp'); 
            ffsolver = 'Newton_Axi.edp';
        end
        ffparams = num2str(Re);        
        BFfilename = [ 'BaseFlow_Re', num2str(Re)];
        
    case ({'axicomp','axicompsponge','axicompcomplex'})
        SF_core_log('n', '## Entering SF_BaseFlow (Axisymmetric Compressible case)');
        ffparams = [' '];
        ffargument = [ffargument, ' -Ma ',num2str(p.Results.Mach)];
        ffargument = [ffargument, ' -Re ',num2str(p.Results.Re)];
        ffsolver = 'Newton_Axi_Comp.edp';
        if(ncores == 1)
            ffbin = 'FreeFem++-mpi';
        else
            ffbin = 'ff-mpirun';
        end

        BFfilename = [ 'BaseFlow_Re', num2str(Re), 'Ma', num2str(Ma)];

    
    case ('axicompcomplex_m') % with azimuthal mode
        SF_core_log('nn', '## Entering SF_BaseFlow (axisymmetric Compressible case COMPLEX)');
        % generating file "Param_Mapping.edp" used by Newton and stab. solver
        %%% Writing parameter file for Adapmesh
        %SFcore_CreateMappingParamFile('Type2',p.Results.MappingParams); %% See auxiliary function of this file
        %if(length(p.Results.MappingParams)==9) % if no parameters are specified then the file must already exist
        %    fid = fopen('Param_Mapping.edp', 'w');
        %        fprintf(fid, '// Parameters for complex mapping (file generated by matlab driver)\n');
        %        fprintf(fid, ['real ParamMapx0 = ', num2str(p.Results.MappingParams(1)), ' ;']);
        %        fprintf(fid, ['real ParamMapx1 = ', num2str(p.Results.MappingParams(2)), ' ;']);
        %        fprintf(fid, ['real ParamMapLA = ',  num2str(p.Results.MappingParams(3)), ' ;']);
        %        fprintf(fid, ['real ParamMapLC = ', num2str(p.Results.MappingParams(4)), ' ;']);
        %        fprintf(fid, ['real ParamMapGC = ',  num2str(p.Results.MappingParams(5)), ' ;']);
        %        fprintf(fid, ['real ParamMapyo = ', num2str(p.Results.MappingParams(6)), ' ;']);
        %        fprintf(fid, ['real ParamMapLAy = ',  num2str(p.Results.MappingParams(7)), ' ;']);
        %        fprintf(fid, ['real ParamMapLCy = ', num2str(p.Results.MappingParams(8)), ' ;']);
        %        fprintf(fid, ['real ParamMapGCy = ',  num2str(p.Results.MappingParams(9)), ' ;']);
        %    fclose(fid);
        %end
        SF_core_log('nn', '## Entering SF_BaseFlow (Axi-COMPLEX COMPRESSIBLE) ');
        ffparams = [num2str(Re), ' ', num2str(p.Results.Mach)];
        ffsolver = 'Newton_Axi_Comp_Sponge.edp';
        %ffbin = 'FreeFem++-mpi';
        BFfilename = [ 'BaseFlow_Re', num2str(Re), 'Ma', num2str(Ma)];
        
    case ('axixrswirl') % axisymmetric WITH SWIRL
        SF_core_log('nn', '## Entering SF_BaseFlow (axisymmetric case WITH SWIRL)');
        ffparams = [ num2str(Re), ' ', num2str(p.Results.Omegax), ' '];
        ffsolver = 'Newton_AxiSWIRL.edp';

  case ('axixrporous') % axisymmetric WITH SWIRL AND POROUS OBJECT
        SF_core_log('nn', '## Entering SF_BaseFlow (axisymmetric case WITH SWIRL AND POROSITY)');
        ffparams = [ num2str(Re), ' ', num2str(p.Results.Omegax), ' ', num2str(p.Results.Darcy), ' ', num2str(p.Results.Porosity)];
        ffsolver = 'Newton_AxiSWIRLPorous.edp';
        
        
    case ('2dcomp')
        %fff = [ ffMPI ' -np ',num2str(ncores) ]; %does not work with FreeFem++-mpi
        %SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams); %% See auxiliary function of this file
        SF_core_log('nn', '## Entering SF_BaseFlow (2D COMPRESSIBLE COMPLEX) ');
        ffparams = [num2str(Re), ' ', num2str(p.Results.Mach), ' ', num2str(p.Results.Omegax), ' ',mesh.symmetry];
        ffsolver = 'Newton_2D_Comp.edp';
        %ffbin = 'FreeFem++-mpi';
        BFfilename = '';%[ 'BaseFlow_Re', num2str(Re), 'Ma', num2str(Ma), 'Omegax', num2str(p.Results.Omegax)];

    case ('2dcompsponge')
        %fff = [ ffMPI ' -np ',num2str(ncores) ]; %does not work with FreeFem++-mpi
        SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams); %% See auxiliary function of this file
        SF_core_log('nn', '## Entering SF_BaseFlow (2D COMPRESSIBLE SPONGE) ');
        ffparams = [num2str(Re), ' ', num2str(p.Results.Mach), ' ', num2str(p.Results.Omegax), ' ',mesh.symmetry];
        ffsolver = 'Newton_2D_Comp_Sponge.edp';
        %ffbin = 'FreeFem++-mpi';
        BFfilename = [ 'BaseFlow_Re', num2str(Re), 'Ma', num2str(Ma), 'Omegax', num2str(p.Results.Omegax)];

    case ({'kaptsov','kaptzov'})
        SF_core_log('nn', '## Entering SF_BaseFlow (Kaptsov) ');
        %ffparams = [num2str(p.Results.Eac), ' ', num2str(p.Results.Pe),' ', num2str(p.Results.Vc)] ;
        ffparams = '';
        ffargument = [ffargument, ' -Eac ', num2str(p.Results.Eac), ' -Pe ', num2str(p.Results.Pe), ' -Vc ' , num2str(p.Results.Vc) ' -epslambda ' , num2str(p.Results.epslambda) ];
        ffsolver = 'Newton_Kaptsov.edp';
        BFfilename = '';

%    case (other cases...)     
%  Add the interface to your own cases here !

    otherwise
        
    if ~strcmp(p.Results.solver,'default')
       SF_core_log('e',['ERROR : problem type ' problemtype ' not recognized ']);
    end
end %switch


if(strcmp(p.Results.solver,'default'))
    SF_core_log('nn',['      ### USING STANDARD StabFem Solver for this class of problems : ',ffsolver]);        
else
        ffsolver = p.Results.solver; 
        SF_core_log('nn',['      ### USING Specified StabFem Solver ',ffsolver]);  
end



%% CHECK IF A BASE FLOW MATCHING ALL METADATA EXISTS ; IF SO LOADING IT

%%% New method to detect if the file already exists in database according to metadata 
%%% Currently only operational for '2d', '2dcomp' 'axixr' and 'axixrswirl' problems 


if ~strcmp(baseflow.datatype,'mesh')
 if (~strcmpi(p.Results.type,'postadapt')&&~strcmpi(p.Results.type,'new'))%%&&baseflow.iter~=0)
  switch lower(problemtype)
    case {'2d','axixr','axixrswirl','2dcomp','unspecified'}
 %     if strcmpi(problemtype,'2d') % other cases not operational yet
     sfs = SF_Status('BASEFLOWS') ;
    if isfield(sfs,'BASEFLOWS')
    for i = 1:length(sfs.BASEFLOWS)  
        if isfield(sfs.BASEFLOWS(i),'meshfilename')&&isfield(baseflow,'meshfilename')&&strcmp(sfs.BASEFLOWS(i).meshfilename,baseflow.meshfilename)
             goodfield = AllMetaDataMatch(sfs.BASEFLOWS(i),p.Results);
            if goodfield==1
                 SF_core_log('n', ' In SF_Baseflow : found a previously computed base flow in database !')
                 SF_core_log('n', ' NB : if you want to force a new computation add ''type'' , ''new'' to the list of options')
                baseflowNEW = SFcore_ImportData(mesh,sfs.BASEFLOWS(i).filename);
                    % patch new interface
                    if isfield(baseflow,'Symmetry') 
                            baseflowNEW.Symmetry = baseflow.Symmetry;
                    end
                    if isfield(baseflow,'solver') 
                            baseflowNEW.solver = baseflow.solver;
                    end
                    % end patch 
                return
            end
            if goodfield==-1
                 SF_core_log('w', ' In SF_Baseflow : problem when trying to detect metadata. Please check your case. It is recommended to include at least one metadata field')
            end
        end
    end
    end
      otherwise
        SF_core_log('nnn', ' In SF_Baseflow : disabling search or a valid field in database. This is only possible for "unspecified" problemtype or a few others ')          
  end
 end
end


SF_core_arborescence('cleanDEBUG');

%% "Include" argument
Include = p.Results.Include;
if strcmp(SF_core_getopt('solver'),'MUMPS')
    Include = [Include,'load "MUMPS" //EOM'];
    Include = [Include,'cout << "loading MUMPS";']; 
end

%% CALL NEWTON SOLVER

    value = SF_core_freefem(ffsolver,'bin',p.Results.ffbin,'parameters',ffparams,'arguments',ffargument,'Include',Include,'ncores',ncores);
    
   
    if ~isempty(BFfilename)
        BFfilename = ['/' BFfilename, '.txt']; % to allow autoindexing mode
    end
%    SFcore_AddMESHFilenameToFF2M([SF_core_getopt('ffdatadir'),'BaseFlow.txt'],mesh.filename); 

    SFcore_AddMESHFilenameToFF2M('BaseFlow.txt',mesh.filename); 
    if (strcmpi(baseflow.datatype,'mesh'))
        SFcore_MoveDataFiles('BaseFlow.txt',['BASEFLOWS' BFfilename ],'cp');
        finalname = SFcore_MoveDataFiles('BaseFlow.txt','MESHBF');
    else
    if(strcmpi(p.Results.type, 'POSTADAPT')==1)
         % after adapt we clean the "BASEFLOWS" directory as the previous baseflows are no longer compatible 
       %  SFcore_MoveDataFiles('BaseFlow.txt',['MESHES' BFfilename ],'cp');
%         SFcore_CleanDir('BASEFLOWS'); 
%        SF_core_arborescence('clean'); % this will erase BASEFLOWS ->>> NO
         finalname = SFcore_MoveDataFiles('BaseFlow.txt',['BASEFLOWS' BFfilename ]);
    else
            % Copy under the expected name
     finalname = SFcore_MoveDataFiles('BaseFlow.txt',[p.Results.store, BFfilename ]);
    end
    end 

   
%% IMPORT DATA
baseflowNEW = SFcore_ImportData(mesh,finalname);

% patch for new generic interface
if strcmp(mesh.problemtype,'unspecified')
    baseflowNEW.solver = p.Results.solver;
    if ~strcmp(p.Results.Symmetry,'N')
        baseflowNEW.Symmetry = p.Results.Symmetry; %obsolete
    end
    SF_core_log('nnn', ' New interface : setting solver and Symmetry for next steps'); 
end
    

%% MESSAGES
message = 'SF_BaseFlow : Base flow converged '; 
     if isfield(baseflowNEW, 'iter')
        message = [message ' in ', num2str(baseflowNEW.iter), ' iterations '];
     end
    if isfield(baseflowNEW, 'Re')  %% adding drag information for blunt-body wake
        message = [message, '; Re = ', num2str(baseflowNEW.Re)];
    end
    if isfield(baseflowNEW, 'Fx')  %% adding drag information for blunt-body wake
        message = [message, '; Fx = ', num2str(baseflowNEW.Fx)];
    end
    if isfield(baseflowNEW, 'Lx')  %% adding drag information for blunt-body wake
        message = [message, '; Lx = ', num2str(baseflowNEW.Lx)];
    end
    if (isfield(baseflowNEW, 'deltaP0') == 1) %% adding pressure drop information for jet flow
        message = [message, '; deltaP0 = ', num2str(baseflowNEW.deltaP0)];
    end
    SF_core_log('n', message);

  if (value==201) 
        SF_core_log('w','Newton iteration DID NOT CONVERGE but final iteration is returned (debug mode)');
        SF_core_log('w',' Be careful NOT to use this flow for subsequent calculations !');
        baseflowNEW.iter = -1;
  end
    
% eventually clean working directory from temporary files
SF_core_arborescence('cleantmpfiles')
 
SF_core_log('d', '### END FUNCTION SF_BASEFLOW ');

end


function mymyrm(filename)
SF_core_syscommand('rm',[SF_core_getopt('ffdatadir') filename]);
end


function res = myexist(filename)
res = exist([SF_core_getopt('ffdatadir') 'BASEFLOWS/' filename],'file');
end



function goodfield = MetaDataMatches(SFSbf,metadata,value,goodfield)
     if goodfield~=0       
            if isfield(SFSbf,metadata)
                if (SFSbf.(metadata)==value)
                    SF_core_log('d',[' metadata ', metadata ' matches']);
                    goodfield=1;
                else
                    SF_core_log('d',[' metadata ', metadata ' does not match']);
                    goodfield=0;
                end
            else
                SF_core_log('d',[' metadata ', metadata ' not available']);
            end
     end
end



function goodfield = AllMetaDataMatch(SFSbf,parser)
SF_core_log('d',['Entering AllMetaDataMatch ']);
   goodfield=-1;
   FF = fieldnames(SFSbf);
   for j=1:length(FF)
       field=FF{j};
     if isnumeric(SFSbf.(field))&&isscalar(SFSbf.(field))      
            if isfield(parser,field)
                if (SFSbf.(field)==parser.(field))
                    SF_core_log('d',[' metadata ', field ' matches']);
                    goodfield=1;
                else
                    SF_core_log('d',[' metadata ', field ' does not match']);
                    goodfield=0;
                    break
                end
            else
                SF_core_log('d',[' metadata ', field ' not available']);
            end
     else
     SF_core_log('d',[' field ', field ' not numerical ']);    
     end
   end
SF_core_log('d',['End AllMetaDataMatch ']);   
end
