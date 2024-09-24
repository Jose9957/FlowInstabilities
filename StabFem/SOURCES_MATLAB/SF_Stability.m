function varargout = SF_Stability(baseflow,varargin)

%> StabFem wrapper for Eigenvalue calculations
%>
%> usage : 
%>   [eigenvalues[,eigenvectors]] = SF_Stability(field, [,param1,value1] [,param2,value2] [...])
%>
%> field is either a "baseflow" structure (with "mesh" structure as a subfield) 
%> or directly a "mesh" structure (for instance in problems such as sloshing where baseflow is not relevant).
%>
%> Output :solver
%> eigenvalues -> array containing the eigenvalues
%> eigenvector -> array of struct objects containing the eigenvectors.
%> 
%> List of accepted parameters (in approximate order of usefulness):
%>
%>  
%>   solver :    Name ('###.edp') of the FreeFem++ solver to be used for the calculation. 
%>               If not specified the solver specified at a previous call
%>               will be used.
%>               Alternatively, if no solver is defined but a "problemtype"
%>               has been defined when creating the mesh, a default solver
%>               relevant to the "problemtype" class of problems will be used.
%>               (Legacy mode, not recommended any more).
%>
%>   Options :  List of options to be transmitted to FreeFem program as list of arguments 
%>                  (Either a cell-array of descriptor-value pairs, a structure, 
%>                  or directly a string like '-Param1 value1 -Param2 value 2'
%>
%>   Include :   A cell-array of strings to be included in the prologue of
%>                the FreeFem file (e.g. {'macro Solver MUMPS \\','load "MUMPS"'} ) 
%>    
%>   shift :     shift for shift-invert algorithm.
%>               value can be either a numerical value (complex), 'prev' to use previously computed eigenvalue, 
%>               or 'cont' to use extrapolated value from two previous computations. 
%>               (obviously 'prev' and 'cont' cannot be used at first call to this function).
%>
%>   nev :       requested number of eigenvalues
%>               (the solver will use Arnoldi method if nev>1 and shift-invert if nev=1)
%>
%>   sort :      how to sort the eigenvalues if nev>1. Accepted values :
%>               'LR' (largest real), 'SR' (smallest real), 'SM' (smallest magnitude), 'SI', 'SIA' (smallest absolute value of imaginary part),
%>               'cont' (sort according to proximity with previous computation; continuation mode) 
%>
%>   Stats :     true (default) : write statistics in database (STATS/) | false : to disable this  
%>
%>   Threshold : This option allows to detect a threshold (by interpolation)  if a change of sign of growth rate
%>               is encountered between the present calculation and the previous one (to be used in loops)
%>               'off' (default) | 'on' / 'single' -> track threshold on leading branch 
%>                               | 'multiple' -W track thresholds on multiple branches
%>
%>   PlotSpectrum : set to 'true' to launch the spectrum explorator (or specify the label of the figure).
%>                  This option will draw the spectrum in figure specified (or 100 if not specified) and will allow to display the eigenmodes 
%>                  by clicking on the corresponding eigenvalue. 
%>
%>  PlotSpectrumField : which field to plot in the spectrum explorator. 
%>
%>  PlotModeOptions : list of keawords/values passed to SF_Plot in spectum explorator mode.
%>               (useful for instance to specify ranges 'xlim','ylim' to be used) 
%>
%>
%>  Since StabFem 3.8 (Nov 2020) all other parameters should now be
%>  transmitted through the 'Options' cell-array (or structure)
%> 
%>  A list of physical parameters (Re, Ma, Fr, m, k) are still recognized by
%>  the interface but should normally not be used any more.
%>
%> 
%> 
%>
%> STABFEM IMPLEMENTATION :
%> According to parameters, this wrapper will launch one of the following
%> FreeFem++ solvers :
%>      'Stab2D.edp'
%>      'StabAxi.edp'
%>       (list to be completed)
%>
%>
%> This program is part of the StabFem project distributed under gnu licence. 
%> Copyright D. Fabre, 2017-2019.
%>
%>
%> 
%> History : 
%> 27/11/2020 : new standarts
%> 3/12/2019 removed "old" management of sensitivity
%> 2/  [eigenvalues[,sensitivity] [,evD,evA]] = SF_Stability(field,'type','S','nev',1, [...])
%> 3/  [eigenvalues[,Endogeneity] [,evD,evA]] = SF_Stability(field,'type','E','nev',1, [...])
%> 4/  [eigenvalues[,sensitivity],evD,evA,Endo] = SF_Stability(field,'type','S','nev',1, [...]) (not recommended)

 SF_core_log('nn','Entering SF_Stability');
 
if (nargout >2)
    SF_core_log('w',' Simultaneous computation of direct/adjoint/sensitivity no longer supported');
    SF_core_log('e',' Please use SF_Sensitivity instead');
end

 if isfield(baseflow,'iter')&&baseflow.iter<0
     if ~SF_core_getopt('ErrorIfDiverge')
        SF_core_log('e' ,' baseflow.iter < 0 ! it seems your previous baseflow computation diverged !');
     else
         SF_core_log('w' ,' baseflow.iter < 0 ! it seems your previous baseflow computation diverged ! Continuing anyway');
     end
     elseif isfield(baseflow,'iter')&&baseflow.iter==0
     SF_core_log('w' ,' baseflow.iter = 0 ! it seems your baseflow was projected after mesh adaptation but not recomputed !');
 end

persistent sigmaPrev sigmaPrevPrev % for continuation on one branch
persistent eigenvaluesPrev % for sort of type 'cont'
persistent counter
%persistent stabsolverprevious % default solver 
if ~isempty(SF_core_getopt('StabSolver'))
    stabsolverprevious = SF_core_getopt('StabSolver');
else
    stabsolverprevious=[];
end
if isempty(counter)
    counter = 0;
end
if isempty(stabsolverprevious)
    stabsolverprevious='';
end

% first clean working directory from temporary files
   SF_core_arborescence('cleantmpfiles')

%% Chapter 1 : management of optionnal parameters
    p = inputParser;
    global TweakedParameters;
    TweakedParameters.list = {};
  
 %% Declaration of parameters
 %    All optional parameters should be declared here. Two posible ways : 
 % 1/  Use "SFcore_addParameter" for parameters which may be inherited from MetaData present in baseflow structure 
 %     (for instance physical parameters such as Re, Ma, etc...). In such cases the default values are defined in the solver
 %     (even if a default value is defined here; it should not be used)
 % 2/  Use "addParameter" otherwise (for numerical parameters such as nev, shift, etc...).  
    
   addParameter(p,'solver','default',@ischar); 
   % to specify the solver if using generic interface (new recommended usage)  
    

     
  %parameters for the eigenvalue solver
   addParameter(p,'shift',1+1i);
   addParameter(p,'nev',10,@isnumeric);
   addParameter(p,'type','D',@ischar); 
   addParameter(p,'guess','no',@isstruct);
   addParameter(p,'guessadj','no',@isstruct); % ??

   
   %parameters for solver options
   addParameter(p,'ncores',1,@isnumeric); % num proc if using mpi
   addParameter(p,'Options',''); 
   addParameter(p,'Include',{}); % string of options e.g. '-NsF 30'
   addParameter(p,'ffbin','default',@ischar); % to use an alternative solver
   
   % parameters for the post-processing options
   addParameter(p,'sort','no',@ischar); 
   addParameter(p,'PlotSpectrum',false);
   addParameter(p,'PlotSpectrumSymbol','');
   addParameter(p,'PlotSpectrumField','default',@ischar); % legacy
   addParameter(p,'PlotModeOptions',{},@iscell);
   addParameter(p,'plot',false); % option not used but possibly passed by SF_Stability_LoopRe
   addParameter(p,'ifdiverge','error');
   addParameter(p,'Store','EIGENMODES');
   
   addParameter(p,'Threshold','on'); % off
   addParameter(p,'Stats',true);

   % parameters for COMPLEX MAPPING
   addParameter(p, 'MappingDef', 'none'); % Array of parameters for the cases involving mapping
   addParameter(p, 'MappingParams', 'default'); % Array of parameters for the cases involving mapping
   
   % physical parameters, problem-dependent, according to "problemtype" (LEGACY METHOD)
   SFcore_addParameter(p, baseflow, 'Re',1,@isnumeric); % Reynolds
   SFcore_addParameter(p, baseflow, 'Ma',0.01,@isnumeric);
   SFcore_addParameter(p, baseflow, 'Omegax',0.,@isnumeric);
   SFcore_addParameter(p, baseflow, 'alpha',0.,@isnumeric);
   SFcore_addParameter(p, baseflow, 'Darcy',0.1,@isnumeric);
   SFcore_addParameter(p, baseflow, 'Porosity',0.95,@isnumeric);  
   SFcore_addParameter(p, baseflow,  'Cu', 0., @isnumeric); % For rheology
   SFcore_addParameter(p, baseflow,  'AspectRatio', 1.0, @isnumeric); % For rheology
   SFcore_addParameter(p, baseflow,  'nRheo', 1.0, @isnumeric); % For rheology
   addParameter(p,'STIFFNESS',0);
   addParameter(p,'MASS',0);
   addParameter(p,'DAMPING',0);
   % parameters for free-surface static problems
    SFcore_addParameter(p, baseflow, 'gamma' ,0.,@isnumeric);
    SFcore_addParameter(p, baseflow, 'rhog',1., @isnumeric);
    SFcore_addParameter(p, baseflow, 'nu' ,0., @isnumeric);
    SFcore_addParameter(p, baseflow, 'beta',1, @isnumeric);
    SFcore_addParameter(p, baseflow, 'GammaBAR',0., @isnumeric);
    SFcore_addParameter(p, baseflow, 'alphaMILES',0., @isnumeric);
    addParameter(p,'typestart','pined');
    addParameter(p,'typeend','pined');
    % parameters for free-surface dynamic problems
    SFcore_addParameter(p, baseflow, 'Oh' ,0.1,@isnumeric);
    SFcore_addParameter(p, baseflow, 'We',0., @isnumeric);
    addParameter(p,'ALEoperator','laplacian', @ischar); 
   %symmetry paramaters for axisymmetric case
   addParameter(p,'m',1,@isnumeric);
   %symmetry parameters for 2D case
   addParameter(p,'k',0,@isnumeric);
   if isfield(baseflow,'mesh')&&isfield(baseflow.mesh,'symmetry')&&strcmpi(baseflow.mesh.symmetry,'s') 
       % legacy ; symmetry should no longer be managed in this way
       symdefault = 'A'; 
   else
       symdefault = 'N'; 
   end
   addParameter(p,'Symmetry',symdefault,@ischar); 
   % parameters for acoustic pipes
   addParameter(p,'BC','SOMMERFELD',@ischar);


   % Parameters for ALE cases (develop ; to be suppressed ; now done differently)
   %addParameter(p,'CancelBF','no',@ischar);
   %addParameter(p,'NsF',.5,@isnumeric);
   %addParameter(p,'FunctionBasis','default',@ischar);
   %addParameter(p, 'ALEOperator' ,'laplacian');
   
   %%% End of definition of parameters
   
   %%% Parsing the parameters...
   parse(p,varargin{:});
   
   
   % parameters for continuation mode
   if(isempty(sigmaPrev))   
       sigmaPrev = p.Results.shift; 
       sigmaPrevPrev = p.Results.shift; 
   end
   if(isempty(eigenvaluesPrev)) 
       eigenvaluesPrev = p.Results.nev : -1 : 1 ; 
   end
   
   if(strcmp(p.Results.shift,'prev')==1)
       shift = sigmaPrev;       
       SF_core_log('d',['   # SHIFT from previous computation = ' num2str(shift)]); 
   elseif(strcmp(p.Results.shift,'cont')==1)      
       shift = 2*sigmaPrev-sigmaPrevPrev;      
       SF_core_log('d',['   # SHIFT extrapolated from two previous computations = ' num2str(shift)]); 
   elseif(isnumeric(p.Results.shift)==1)
       shift = p.Results.shift;
       SF_core_log('d',['   # SHIFT specified by user = ' num2str(shift)]); 
   else
       error('   # ERROR in SF_Stabilty while specifying the shift')
   end
   
   TweakedParameters.shift = shift;

%% position input files

   if(strcmpi(baseflow.datatype,'mesh')==1)
       % first argument is a simple mesh
       ffmesh = baseflow; 
       SFcore_MoveDataFiles(ffmesh.filename,'mesh.msh','cp');
   else
       % first argument is a base flow
       ffmesh = baseflow.mesh;
       SFcore_MoveDataFiles(ffmesh.filename,'mesh.msh','cp');
       SFcore_MoveDataFiles(baseflow.filename,'BaseFlow.txt','cp');
   end
   
   if(isstruct(p.Results.guess))
       SFcore_MoveDataFiles(p.Results.guess.filename,'Eigenmode_guess.txt'); 
   else
      mymyrm('Eigenmode_guess.txt') % TODO : add parameter to put a guess file only when required
   end
   
    if(isstruct(p.Results.guessadj))
       SFcore_MoveDataFiles(p.results.guessadj.filename,'EigenmodeAdj_guess.txt'); 
   else
      mymyrm('EigenmodeAdj_guess.txt') % TODO : add parameter to put a guess file only when required
   end
   
%% Chapter 2 : select the relevant freefem script

% explanation : we will launch a command with the form 
%   echo "47 0 0.7 A D 10" | FreeFem++ Stab2D.edp -opt1 (value1) -opt2 (value2) 
%  
% this will be slitted in the form :
%   echo "argumentstring" | "fff" "solver" and processed thanks to SF_core_freefem
% so in each case we have to a) construct the argumentstring containing the parameters,
% b) define the fff command (usually FreeFem++ but can be FreeFem+++-mpi in some cases
%  and c) define the default solver (which can be replaced by a custom one)
%

if strcmpi(ffmesh.problemtype,'2d')&&((p.Results.STIFFNESS~=0)||(p.Results.MASS~=0))
  SF_core_log('d',' USING solver for 2D mobile object') 
  ffmesh.problemtype='2Dmobile';
end


SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams);    % put it here in all cases (some drivers always require Param_Mapping.edp file)


%ffargument = ' ';
ffargument = p.Results.Options;
ffargument = SF_options2str(ffargument); % transforms into a string
ffbin = p.Results.ffbin; % Freefem binary excutable

switch lower(ffmesh.problemtype)
    
      case ('unspecified')
        % This is the new generic interface, treating all parameters through getARGV
        argumentstring = ' ' ;
        ffargument2 = SF_CreateArgumentString(p,TweakedParameters); % assembly from parameters
        ffargument = [ffargument,ffargument2];
        if ~strcmp(p.Results.solver,'default')
             solver = p.Results.solver;
             stabsolverprevious = p.Results.solver;
             if isempty(SF_core_getopt('StabSolver'))
                SF_core_setopt('StabSolver',stabsolverprevious);
             end
             SF_core_log('nn',['## SF_Stability : using specified solver ',solver ' with generic interface']);  
        elseif ~isempty(stabsolverprevious)
             solver = stabsolverprevious;
             SF_core_log('nn',['## SF_Stability : using previously specified solver ',solver ' with generic interface']);  
        else
            SF_core_log('e',' No solver specified !')
        end
        
        case({'2d'})
         % 2D flow (cylinder, etc...)

         
         argumentstring = [' '];
        ffargument = [ffargument, ' -Re ',num2str(p.Results.Re)];
        ffargument = [ffargument, ' -shiftr ',num2str(real(shift))];
        ffargument = [ffargument, ' -shifti ',num2str(imag(shift))];
        ffargument = [ffargument, ' -k ',num2str(p.Results.k)];
        ffargument = [ffargument, ' -iadjoint ',num2str(p.Results.type)];
        ffargument = [ffargument, ' -nev ',num2str(p.Results.nev)];
        if(p.Results.ncores == 1)
            ffbin = 'FreeFem++-mpi';
            if (p.Results.k==0)
                 SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
                SF_core_log('nn','      ### USING 2D Solver');
                 argumentstring = '';
                 ffargument = [ffargument,... 
                         ' -Re ', num2str(p.Results.Re), ' -shift_r  ',  num2str(real(shift)),' -shift_i ', num2str(imag(shift)),...
                         ' -Symmetry ', p.Results.Symmetry ' -type ', p.Results.type, ' -nev ' num2str(p.Results.nev) ];
                 solver =  'Stab_2D.edp';
            else
                SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
                SF_core_log('nn',['      ### 3D Stability of 2D Base-Flow with k = ',num2str(p.Results.k)]);
                argumentstring = [num2str(p.Results.Re) ' ' num2str(p.Results.k) ' '  num2str(real(shift)) ....
                    ' ' num2str(imag(shift)) ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev)  ];             
                solver =  'Stab2D_Modes3D.edp';                   end
        else
            ffbin = 'ff-mpirun';
            solver =  'Stab_2D_Parallel.edp'; 
        end
        
%          if(p.Results.k==0)
%             % 2D Baseflow / 2D modes
%         SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
%         SF_core_log('nn','      ### USING 2D Solver');
% %        argumentstring = [ num2str(p.Results.Re) ' '  num2str(real(shift)) ' ' num2str(imag(shift))... 
% %                             ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev)  ];         
% %        solver =  'Stab2D_OldInterface.edp';
%          argumentstring = '';
%          ffargument = [ffargument,... 
%                  ' -Re ', num2str(p.Results.Re), ' -shift_r  ',  num2str(real(shift)),' -shift_i ', num2str(imag(shift)),...
%                  ' -Symmetry ', p.Results.Symmetry ' -type ', p.Results.type, ' -nev ' num2str(p.Results.nev) ];
%          solver =  'Stab_2D.edp';
%          else 
%              % 2D BaseFlow / 3D modes
%                  SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
%         SF_core_log('nn',['      ### 3D Stability of 2D Base-Flow with k = ',num2str(p.Results.k)]);
%         argumentstring = [num2str(p.Results.Re) ' ' num2str(p.Results.k) ' '  num2str(real(shift)) ....
%             ' ' num2str(imag(shift)) ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev)  ];             
%         solver =  'Stab2D_Modes3D.edp';                 
% 
%          end
         
         
          case({'2d_2dof'})
         % 2D flow (cylinder, etc...)

         if(p.Results.k==0)
            % 2D Baseflow / 2D modes
        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn','      ### USING 2D Solver');
%        argumentstring = [ num2str(p.Results.Re) ' '  num2str(real(shift)) ' ' num2str(imag(shift))... 
%                             ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev)  ];         
%        solver =  'Stab2D_OldInterface.edp';
         argumentstring = '';
         ffargument = [ffargument,... 
                 ' -Re ', num2str(p.Results.Re), ' -shift_r  ',  num2str(real(shift)),' -shift_i ', num2str(imag(shift)),...
                 ' -Symmetry ', p.Results.Symmetry ' -type ', p.Results.type, ' -nev ' num2str(p.Results.nev) ];
         solver =  'Stab_2D_2DOF.edp';
         else 
             % 2D BaseFlow / 3D modes
                 SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn',['      ### 3D Stability of 2D Base-Flow with k = ',num2str(p.Results.k)]);
        argumentstring = [num2str(p.Results.Re) ' ' num2str(p.Results.k) ' '  num2str(real(shift)) ....
            ' ' num2str(imag(shift)) ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev)  ];             
        solver =  'Stab_2D_2DOF.edp';                 

         end

     case('acousticaxi')
     
     SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
     SF_core_log('nn','      ### USING Axisymmetric Solver');
     argumentstring = [ (p.Results.BC) ' '  num2str(real(shift)) ' ' num2str(imag(shift)) ...
                          ' '  num2str(p.Results.nev) ];
     solver = 'StabAcoustics.edp';
% 
%   case({'2d','2d_2dof'})
%      
%      SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
%      if strcmp(p.Results.MappingDef,'none')
%         SF_core_log('nn','      ### USING Axisymmetric Solver');
%         solver =  'Stab_2D_Parallel.edp'; 
%      else
%          SF_core_log('n','      ### USING Axisymmetric Solver WITH COMPLEX MAPPING');
%          SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams);    
%          
%          if (p.Results.m==0)
%              solver =  'Stab_2D_Parallel.edp'; % because of a strange bug
%          else
%              solver =  'Stab_2D_Parallel.edp'; % Normally this one should work for all cases
%          end
%      end
%         argumentstring = [' '];
%         ffargument = [ffargument, ' -Re ',num2str(p.Results.Re)];
%         ffargument = [ffargument, ' -shiftr ',num2str(real(shift))];
%         ffargument = [ffargument, ' -shifti ',num2str(imag(shift))];
%         ffargument = [ffargument, ' -kWaveNumber ',num2str(p.Results.k)];
%         ffargument = [ffargument, ' -iadjoint ',num2str(p.Results.type)];
%         ffargument = [ffargument, ' -nev ',num2str(p.Results.nev)];
%         if(p.Results.ncores == 1)
%             ffbin = 'FreeFem++-mpi';
%         else
%             ffbin = 'ff-mpirun';
%         end
   
     
     
  case({'axixr','axixrcomplex','axixrswirl'})
     
     SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
     if strcmp(p.Results.MappingDef,'none')
        SF_core_log('nn','      ### USING Axisymmetric Solver');
        solver =  'Stab_Axi_Parallel.edp'; 
     else
         SF_core_log('n','      ### USING Axisymmetric Solver WITH COMPLEX MAPPING');
         SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams);    
         
     end
        argumentstring = [' '];
        ffargument = [ffargument, ' -Re ',num2str(p.Results.Re)];
        ffargument = [ffargument, ' -shift_r ',num2str(real(shift))];
        ffargument = [ffargument, ' -shift_i ',num2str(imag(shift))];
        ffargument = [ffargument, ' -m ',num2str(p.Results.m)];
        ffargument = [ffargument, ' -iadjoint ',num2str(p.Results.type)];
        ffargument = [ffargument, ' -nev ',num2str(p.Results.nev)];
        if(p.Results.ncores == 1)
            ffbin = 'FreeFem++-mpi';
            if (p.Results.m==0)
                 solver =  'StabAxi_m0.edp'; % because of a strange bug
             else
                 solver =  'StabAxi_OldInterface.edp'; % Normally this one should work for all cases
            end
        else
            ffbin = 'ff-mpirun';
            solver =  'Stab_Axi_Parallel.edp'; 
        end


                         
    case('axixrporous')
    
     SF_core_log('n',['      ### FUNCTION SF_Stability POROUS : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
     SF_core_log('nn','      ### USING Axisymmetric Solver WITH POROSITY AND SWIRL');
     argumentstring = [ num2str(p.Results.Re) ' ' num2str(baseflow.Omegax) ' ' num2str(baseflow.Darcy) ' ' num2str(baseflow.Porosity) ' '  num2str(real(shift)) ' ' num2str(imag(shift))... 
                             ' ' num2str(p.Results.m) ' ' p.Results.type ' ' num2str(p.Results.nev) ];           
     solver =  'StabAxi_Porous.edp';
      
    case('2drheology')
         % 2D flow (cylinder, etc...)

         if(p.Results.k==0)
            % 2D Baseflow / 2D modes
        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn','      ### USING 2D Solver with Rheology');
        argumentstring = [ num2str(p.Results.Re) ' '  num2str(real(shift)) ' ' num2str(imag(shift))... 
                             ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev)  ];             
        solver =  'Stab2D_Rheology.edp';
        else
          % TO BE DONE 
        end
 

    
     case('2dboussinesq')
        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn','      ### USING 3D solver under Boussinesq approximation');
        argumentstring = [ num2str(p.Results.k) ' '  num2str(real(shift)) ' ' num2str(imag(shift))... 
                              ' ' p.Results.type ' ' num2str(p.Results.nev)  ];             
        solver =  'Stab2D_Boussinesq_Modes3D.edp';
    
         
        
    case('axicompcomplex')
         % AxiCompCOMPLEX flow (Whistling jet, etc...)

        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('n','      ### USING Axi compressible COMPLEX Solver');
        argumentstring = [' " ' num2str(p.Results.Re) ' ' num2str(p.Results.Ma) ' ' num2str(real(shift)) ' ' num2str(imag(shift))... 
                             ' ' num2str(p.Results.m) ' ' num2str(p.Results.type) ' ' num2str(p.Results.nev) ' " '];
        solver =  'Stab_Axi_Comp_COMPLEX.edp';
        
    case({'axicomp','axicompsponge'})
         % AxiCompCOMPLEX flow (Whistling jet, etc...)
        if (p.Results.m==0)
             solver =  'Stab_mAxi_Comp.edp';
         else
             solver =  'Stab_mAxi_Comp.edp'; 
         end
        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('n','      ### USING Axi compressible with SPONGE Solver');
        argumentstring = [' '];
        ffargument = [ffargument, ' -Ma ',num2str(p.Results.Ma)];
        ffargument = [ffargument, ' -Re ',num2str(p.Results.Re)];
        ffargument = [ffargument, ' -shiftr ',num2str(real(shift))];
        ffargument = [ffargument, ' -shifti ',num2str(imag(shift))];
        ffargument = [ffargument, ' -m ',num2str(p.Results.m)];
        ffargument = [ffargument, ' -iadjoint ',num2str(p.Results.type)];
        ffargument = [ffargument, ' -nev ',num2str(p.Results.nev)];
        if(p.Results.ncores == 1)
            ffbin = 'FreeFem++-mpi';
        else
            ffbin = 'ff-mpirun';
        end

         
    case('axicompcomplex_m')
         % AxiCompCOMPLEX flow (Whistling jet, etc...)

        % 2D Baseflow / 2D modes
        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn','      ### USING Axi compressible with azimuthal component COMPLEX Solver');
        if(p.Results.Symmetry == 'A')
            symmetry = 0;
        elseif(p.Results.Symmetry == 'S')
            symmetry = 1;
        elseif(p.Results.Symmetry == 'N')
            symmetry = 2;
        end
        
        if(p.Results.type == 'D')
            typeEig = 0;
        elseif(p.Results.type == 'A')
            typeEig = 1;
        elseif(p.Results.type == 'S')
            typeEig = 2;
        else
            typeEig = 0;
        end
        argumentstring = ['  ' num2str(p.Results.Re) ' ' num2str(p.Results.Ma) ' ' num2str(real(shift)) ' ' num2str(imag(shift))... 
                             ' ' num2str(symmetry) ' ' num2str(typeEig) ' ' num2str(p.Results.nev) '  '];            
        solver =  'Stab_Axi_Comp_COMPLEX_m.edp';

    case('2dcomp')
         % 2D flow (cylinder, etc...)

            % 2D Baseflow / 2D modes
        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn','      ### USING 2D compressible Solver');
        if(p.Results.k==0)
            argumentstring = ['  ' num2str(p.Results.Re) ' ' num2str(p.Results.Ma) ' ' num2str(real(shift)) ' ' num2str(imag(shift))... 
                                 ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev) '  '];
           % fff = [ ffMPI ' -np ',num2str(ncores) ]; does not work with FreeFem++-mpi

            solver =  'Stab2D_Comp.edp';

        else
            argumentstring = ['  ' num2str(p.Results.k) ' ' num2str(p.Results.Re) ' ' num2str(p.Results.Ma) ' ' num2str(real(shift)) ' ' num2str(imag(shift))... 
                                 ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev) '  '];

            solver =  'Stab2D_Comp_Modes3D.edp';
        end
    
    case('2dcompsponge')
         % 2D flow (cylinder, etc...)

            % 2D Baseflow / 2D modes
        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn','      ### USING 2D compressible Solver');
        argumentstring = ['  ' num2str(p.Results.Re) ' ' num2str(p.Results.Ma) ' ' num2str(real(shift)) ' ' num2str(imag(shift))... 
                                 ' ' p.Results.Symmetry ' ' p.Results.type ' ' num2str(p.Results.nev) '  '];

        solver =  'Stab2D_Comp_Sponge.edp';

        
    case('2dmobile')
        % for spring-mounted cylinder
             
        SF_core_log('n',['      ### FUNCTION SF_Stability VIV : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('nn','      ### USING 2D Solver FOR MOBILE OBJECT (e.g. spring-mounted)');
        argumentstring = [ num2str(p.Results.Re) ' ' num2str(p.Results.MASS) ' ' num2str(p.Results.STIFFNESS) ' '... 
                            num2str(p.Results.DAMPING) ' ' num2str(real(shift)) ' ' num2str(imag(shift)) ' ' p.Results.Symmetry...
                            ' ' p.Results.type ' ' num2str(p.Results.nev)]; 
        solver = 'Stab2D_VIV.edp';
       
     case('axifsstatic')
        % NEW VERSION for oscillations of a free-surface problem (liquid bridge, hanging drops/attached bubbles, etc...)             
        if(p.Results.nu==0)
        SF_core_log('n',['      ### FUNCTION SF_Stability FREE SURFACE POTENTIAL : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
           
        argumentstring = '' ; 
        ffargument = [ ' -alphaMiles ', num2str(p.Results.alphaMILES) ' -typestart ' ...
        p.Results.typestart ' -typeend ' p.Results.typeend  ' -m ' num2str(p.Results.m) ' -nev '... 
        num2str(p.Results.nev)  ' -shift_r ' num2str(real(p.Results.shift)) ' -shift_i ' num2str(imag(p.Results.shift)) ' '];
        solver =  'StabAxi_FS_Potential.edp';

        else
          SF_core_log('n',['      ### FUNCTION SF_Stability FREE SURFACE VISCOUS : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
          argumentstring = '' ; 
          ffargument = [ ' -nu ', num2str(p.Results.nu) ' -typestart ' ...
          p.Results.typestart ' -typeend ' p.Results.typeend  ' -m ' num2str(p.Results.m) ' -nev '... 
          num2str(p.Results.nev)  ' -shift_r ' num2str(real(p.Results.shift)) ' -shift_i ' num2str(imag(p.Results.shift)) ' '];
          solver =  'StabAxi_FS_Viscous.edp';
        end 
    
    case('3dfreesurfacestatic')
        % OBSOLETE VERSION for oscillations of a free-surface problem (liquid bridge, hanging drops/attached bubbles, etc...)             
        if(p.Results.nu==0)
        SF_core_log('n',['      ### FUNCTION SF_Stability FREE SURFACE POTENTIAL : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        argumentstring = ['  ' ... //num2str(p.Results.gamma) ' ' num2str(p.Results.rhog) ' ' num2str(p.Results.GammaBAR) ' '...
        num2str(p.Results.nu) ' ' num2str(p.Results.alphaMILES) ' ' ...
        p.Results.typestart ' ' p.Results.typeend  ' ' num2str(p.Results.m) ' '... 
        num2str(p.Results.nev)  ' ' num2str(real(p.Results.shift)) ' ' num2str(imag(p.Results.shift)) ' '];
        solver =  'StabAxi_FreeSurface_Potential.edp';

        else
        SF_core_log('n',['      ### FUNCTION SF_Stability FREE SURFACE VISCOUS : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        argumentstring = ['  '  num2str(p.Results.nu) ...
            ' ' p.Results.typestart ' ' p.Results.typeend  ' '...
            ' ' num2str(p.Results.m) ' ' num2str(real(p.Results.shift)) ' ' num2str(imag(p.Results.shift)) ' ' num2str(p.Results.nev) '  '];
        solver =  'StabAxi_FreeSurface_Viscous.edp';
        end

        
        
        
        
case('strainedbubble')
%         Axi free surface ALE (p. BONNEFIS, case STRAINED BUBBLE)
%         TO DEBUG IF NEEDED... The corresponding solvers are not
%         up-to-date.
%    solver = p.Results.solver;
     if strcmp(p.Results.solver,'Stab_Axi_ALE_StrainedBubble.edp')||strcmp(p.Results.solver,'Stab_Axi_ALE_StrainedBubble_m0.edp')
         % 2019 solver to be debugged
       SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
       SF_core_log('nn','       ### for FREE-surface flow USING ALE solver');
       symmetry = 1;
        if(p.Results.Symmetry == 'A')
            symmetry = -1;
        elseif(p.Results.Symmetry == 'S')
            symmetry = 1;
        end
        NsF = 20; % number of terms in the Fourier expansion
        argumentstring = ['  1 ' num2str(p.Results.m) ' ' num2str(symmetry) ' ' ...
        num2str(p.Results.Oh) ' ' num2str(p.Results.We) ' ' num2str(p.Results.nev) ' ' ... 
        num2str(real(shift)) ' ' num2str(imag(shift)) ' ' num2str(NsF) ' '  p.Results.ALEoperator '  '];
        %if p.Results.m==0 && symmetry ==1
        %    solver =  'Stab_Axi_Surface_ALE_Fourier_m0.edp';
        %else
           % solver =  'Stab_Axi_ALE_StrainedBubble.edp';
        %end
     else
       SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('n','       ### for FREE-surface flow USING GENERIC ALE solver');
        symmetry = 1;
        if(p.Results.Symmetry == 'A')
            symmetry = -1;
        elseif(p.Results.Symmetry == 'S')
            symmetry = 1;
        elseif(p.Results.Symmetry == 'N')
            symmetry = 0;
        end
        argumentstring = [' " ' num2str(p.Results.m) ' ' num2str(symmetry) ' ' ...
        num2str(p.Results.nev) ' ' num2str(real(shift)) ' ' num2str(imag(shift)) ' " '];
%        fff =  ffMPI ; 
        solver =  'Stability_FreeSurface_ALE.edp';    
      end 
    
    case({'axifreesurf','alebucket'})
         % Axi free surface ALE (p. BONNEFIS, GENERIC CASE INCLUDING ROTATION)

        SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);
        SF_core_log('n','       ### for FREE-surface flow USING ALE solver');
        symmetry = 1;
        if(p.Results.Symmetry == 'A')
            symmetry = -1;
        elseif(p.Results.Symmetry == 'S')
            symmetry = 1;
        elseif(p.Results.Symmetry == 'N')
            symmetry = 0;
        end
        argumentstring = [' " ' num2str(p.Results.m) ' ' num2str(symmetry) ' ' ...
        num2str(p.Results.nev) ' ' num2str(real(shift)) ' ' num2str(imag(shift)) ' " '];
%        fff =  ffMPI ; 
        
        solver =  'Stability_FreeSurface_ALE.edp';   
        %ffargument = [ffargument,' -CancelBF ', p.Results.CancelBF];
        %ffargument = [ffargument, ' -NsF ',num2str(p.Results.NsF)];
        %ffargument = [ffargument, ' -FunctionBasis ',p.Results.FunctionBasis];
        %ffargument = [ffargument, ' -ALEOperator ',p.Results.ALEOperator];
        
    %case(...)    
    % adapt to your case !
    
    otherwise
        error(['Error in SF_Stability : "problemtype =',ffmesh.problemtype,'  not possible or not yet implemented !'])
end

%ffargument = [ffargument p.Results.Options];


%% Chapter 3-0 : Macros to include to specify eigenvalue solver
Include = p.Results.Include;

if strcmp(SF_core_getopt('solver'),'MUMPS')
    Include = [Include,'load "MUMPS" //EOM']; 
    Include = [Include,'cout << "loading MUMPS";'];
end
if ~isempty(SF_core_getopt('eigensolver'))
  Include = [Include, ['macro EIGENSOLVER ', SF_core_getopt('eigensolver') ,'  //EOM'] ];
else
  Include = [Include, ['macro EIGENSOLVER SLEPC  //EOM'] ];
  SF_core_log('w',' Global option eigensolver not defined !!! assuming SLEPC');
end

if ~strcmp(SF_core_getopt('eigensolver'),'ARPACK')
    Include = [Include,'cout << "loading SLEPc-complex" << endl;'];
    Include = [Include,'load "PETSc-complex" '];
    Include = [Include,'load "SLEPc-complex" '];
    Include = [Include,'macro dimension() 2 //EOM']; 
    Include = [Include,'include "macro_ddm.idp" // for build (domain decomposition)']; 
end


%% Chapter 3 : launch the ff solver

%SF_core_log('n',['      ### FUNCTION SF_Stability : computation of ' num2str(p.Results.nev) ' eigenvalues/modes (DIRECT) with FF solver']);

if ~strcmpi(ffmesh.problemtype,'unspecified')&&~(strcmpi(p.Results.solver,'default'))
        solver = p.Results.solver; 
        SF_core_log('nn',['      ### USING specified StabFem Solver        ',solver]);  %
end

    status = SF_core_freefem(solver,'parameters',argumentstring,'arguments',ffargument,'bin',ffbin,'Include',Include,'ncores',p.Results.ncores);

if (status==202) 
        SF_core_log('w','SHIFT-INVERT iteration DID NOT CONVERGE !');
        ev=NaN;
        em.iter = -1;
        varargout = {ev,em}; 
        return
elseif (status>0)
        SF_core_log('e','Stop here');
end



%% Chapter 4 : post-processing

%% Read Spectrum file

if exist([SF_core_getopt('ffdatadir') 'Spectrum.ff2m'],'file')
    % new method requiring a file Spectrum.txt 
    Spectrum = SFcore_ImportData([SF_core_getopt('ffdatadir') 'Spectrum.txt']);
    eigenvalues = Spectrum.lambda;
else
  % old method
  SF_core_log('w','It is now advised to generate a file Spectrum.ff2m in your stability solvers (see examples, e.g. Stab_2D.edp)');
  rawData1 = myimportdata('Spectrum.txt');
  EVr = rawData1(:,1);
  EVi = rawData1(:,2); 
  eigenvalues = EVr+1i*EVi;
  Spectrum.lambda = eigenvalues;
  Spectrum.shift = ones(1,length(eigenvalues))*shift;
  Spectrum.isadj = ones(1,length(eigenvalues))*strcmp(p.Results.type,"A");
  Spectrum.datadescriptors = 'lambda_r,lambda_i,shift_r,shift_i,isadj';
  evfound = length(eigenvalues);
  if (evfound~=p.Results.nev)
    SF_core_log('w',[' Expected ',num2str(p.Results.nev), ' Eigenmodes but the solver could only compute ',num2str(evfound)]);
  end
end
evfound = length(eigenvalues);

SF_core_log('n',['SF_Stability : successfully computed ',num2str(p.Results.nev),' eigenvalues ; leading one = ',num2str(eigenvalues(1))]);

% Append eigenvalues to StabStats.txt / StabStats.ff2m
if ~isfield(baseflow,'INDEXING')
  baseflow.INDEXING.soundspeed = 1; % Very ugly fix for acoustic pipe
end



% sort eigenvalues 
%           (NB the term 1e-4 is a trick so that the sorting still
%           works when eigenvalues come in complex-conjugate pairs)
    switch lower(p.Results.sort)
        case('lr') % sort by decreasing real part of eigenvalue
            [~,o]=sort(-real(eigenvalues)+1e-4*abs(imag(eigenvalues)));
        case('sr') % sort by increasing real part of eigenvalue
            [~,o]=sort(real(eigenvalues)+1e-4*abs(imag(eigenvalues)));
        case('sm') % sort by increasing magnitude of eigenvalue
            [~,o]=sort(abs(eigenvalues)+1e-4*abs(imag(eigenvalues)));
        case('lm') % sort by decreasing magnitude of eigenvalue
            [~,o]=sort(-abs(eigenvalues)+1e-4*abs(imag(eigenvalues)));
        case('si') % sort by increasing imaginary part of eigenvalue
            [~,o]=sort(imag(eigenvalues));  
        case('sia') % sort by increasing imaginary part (abs) of eigenvalue
            [~,o]=sort(abs(imag(eigenvalues))+1e-4*imag(eigenvalues)+1e-4*real(eigenvalues));
        case('dist') % sort by increasing distance to the shift
            [~,o]=sort(abs(eigenvalues-shift));  
        case('cont') % sort using continuation (to connect with previous branches)
            eigenvaluesSORT = eigenvalues;
            for i=1:length(eigenvalues)    
                [~, index] = min(abs(eigenvaluesSORT-eigenvaluesPrev(i)));
                o(i) = index;
                eigenvaluesSORT(index)=NaN;
            end
        case('no')
            o = 1:length(eigenvalues);
        otherwise 
            SF_core_log('w','sorting option not recognized');
            o = 1:length(eigenvalues);
    end
    eigenvalues=eigenvalues(o);     
    eigenvaluesPrev = eigenvalues;

% updating two previous iterations
if(strcmp(p.Results.shift,'cont')==1)
sigmaPrevPrev = sigmaPrev;
sigmaPrev = eigenvalues(1);
else
sigmaPrevPrev = eigenvalues(1);
sigmaPrev = eigenvalues(1); 
end

    if (nargout>1)||p.Results.PlotSpectrum %% process output of eigenmodes

        
    eigenvectors=[];
        for iev = 1:min(p.Results.nev,evfound)
        expectedname = ['Eigenmode' num2str(iev) '.txt'];
        % This is the expected name with new preconizations
        if ~exist([SF_core_getopt('ffdatadir'),'/',expectedname],'file')
            % Try legacy formats which may be used by "old" solvers
            
            SF_core_log('w',[' the eigenmode file should be named ',expectedname]);
            if exist([SF_core_getopt('ffdatadir'),'/','EigenmodeA' num2str(iev) '.txt'],'file')
                expectedname = ['EigenmodeA' num2str(iev) '.txt'];
                SF_core_log('w',[' Detected legacy name : ',expectedname]);
            elseif exist([SF_core_getopt('ffdatadir'),'/','Eigenmode.txt'],'file')
                 expectedname = 'Eigenmode.txt';
                 SF_core_log('w',[' Detected legacy name : ',expectedname]);
            elseif exist([SF_core_getopt('ffdatadir'),'/','EigenmodeA.txt'],'file')
                 expectedname = 'EigenmodeA.txt';
                 SF_core_log('w',[' Detected legacy name : ',expectedname]);
            else
                SF_core_log('w',' Did not detect any eigenmode file !');
            end
        end
        SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename,baseflow.filename);
        filename{iev} = SFcore_MoveDataFiles(expectedname,[p.Results.Store, '/']);
        %egv = SFcore_ImportData(ffmesh,filename);
        egv = SFcore_ImportData(filename{iev},'metadataonly');
        egv.type=p.Results.type;
        %eigenvectors(iev) = egv;
        eigenvectors = [eigenvectors egv];
        end
        eigenvectors=eigenvectors(o);%sort the eigenvectors with the same filter as the eigenvalues

    
        %%  Generating indexes for "EIGENVALUES" and "THRESHOLDS"
if p.Results.Stats
    SF_core_log('nn','Writing eigenvalues in stats database')
    SF_WriteEVstatsNew(Spectrum,baseflow,'StabStats',p.Results.Threshold,filename);
else
    SF_core_log('nn','Disabling Writing eigenvalues in stats database')
end
        
    end
    switch(nargout)
        case(1)
    varargout = {eigenvalues};
%     varargout = eigenvectors
        case(2)
             if(p.Results.type=='S')
                varargout = {eigenvalues,sensitivity};
             elseif(p.Results.type=='E')
                varargout = {eigenvalues,Endo};  
             else
                  varargout = {eigenvalues,eigenvectors}; 
             end
        case(3)
    error( 'number of output arguments not valid...' )
        case(4)
            if(p.Results.type=='S')
                varargout = {eigenvalues,sensitivity,evD,evA};  
            elseif(p.Results.type=='E')
                varargout = {eigenvalues,Endo,evD,evA};  
            end
        case(5)
            varargout = {eigenvalues,sensitivity,evD,evA,Endo}; 
    end
       
     % FINALLY : in spectrum explorator mode, plot the spectrum
    if p.Results.PlotSpectrum
        if isnumeric(p.Results.PlotSpectrum)
            numfig = p.Results.PlotSpectrum;
        else
            numfig = 100;
        end
        
        figure(numfig);
        mycolors = 'brgcmyk'; 
        thecolor = mycolors(mod(counter,7)+1);
        counter = counter+1;
        if strcmp(p.Results.PlotSpectrumSymbol,'')
            theplotsymbol = ['*',thecolor];
        else
            theplotsymbol = p.Results.PlotSpectrumSymbol;
        end
        
        if ~strcmp(p.Results.PlotSpectrumField,'default')
            if ~SF_core_isopt('PlotSpectrumField')
                SF_core_log('w',' PlotSpectrumField is now a global variable ; use SF_core_setopt(''PlotSpectrumField'',[...])');
            end
            SF_core_setopt('PlotSpectrumField',p.Results.PlotSpectrumField);
        end
        if ~isempty(p.Results.PlotModeOptions)
            if ~SF_core_isopt('PlotModeOptions')
                SF_core_log('w',' PlotModeOptions is now a global variable ; use SF_core_setopt(''PlotModeOptions'',[...])');
            end
            SF_core_setopt('PlotModeOptionsLEG',p.Results.PlotSpectrumField);
        end
        if ~strcmp(p.Results.type,'A') 
            plot(real(shift),imag(shift),['o',thecolor]);hold on;
        else
            plot(real(shift),-imag(shift),['o',thecolor]);hold on;
        end
        for ind = 1:length(eigenvalues)
            h = plot(real(eigenvalues(ind)),imag(eigenvalues(ind)),theplotsymbol);hold on;
            set(h,'buttondownfcn',{@SFcore_plotmode,eigenvectors(ind).filename});
        end
    xlabel('\lambda_r');ylabel('\lambda_i');
    title('Spectrum (click eigenvalue to display eigenmode)');
    pause(0.1);
    end
        
   SF_core_log('d','END Function SF_Stability :');  
    
end

function mymyrm(filename)
SF_core_syscommand('rm',[SF_core_getopt('ffdatadir') filename]);
end

function data = myimportdata(filename)
data = importdata([SF_core_getopt('ffdatadir') filename]);
end

