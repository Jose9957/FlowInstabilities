%> @file SOURCES_MATLAB/SF_HBN.m
%> @brief StabFem wrapper for Harmonic Balance at Nth order calculation (Newton iteration)
%>
%> @param[in] varargin: list of parameters and associated values
%> @param[out] meanflow: meanflow solved by Newton iterations
%> @param[out] mode: List of harmonics solved by Newton iterations
%>
%> usage: 
%> 1. [meanflow,mode,mode2] = SF_HBN(meanflow,mode,['Param1',Value1,...])
%>
%> in mode 1 (first and second argument are a previously computed meanflow and list of harmonics ) 
%             these fields will be used to initialize the Newton iteration.  
%>
%> This wrapper will launch the Newton FreeFem++ program of the corresponding
%>  case.
%>
%> List of valid parameters:
%>   - NModes      Number of harmonics to be calculated
%>   - Re          Reynolds number
%>   - Ma          Mach number (for compressible cases)
%>   - symmetry    Symmetry of modes for cartesian cases ("N","S","A")
%>   - symmetryBF  Symmetry of the meanflow ("S","A","N")
%>   - ncores      Number of cores used for the parallel computation (by default ncores=1)
%>   - omegaguess  Guess for the fundamental frequency
%>   - PCtype      Preconditioning technique ("none", "bjacobi")
%>
%>
%> SF IMPLEMENTATION:
%> Depending on set parameters, this wrapper will select and launch one of the
%>  following FreeFem++ solvers:
%>       'HBN_2D.edp'
%>       'MPIHBN_Axi_Comp.edp'
%>       'MPIHBN_2D_Comp.edp'
%>         (... maybe many others...)
%>
%>
%> TODO: Recovery of previously computed fields automatically as it is done in SF_BaseFlow.
%>
%> @author Javier Sierra
%> @date 2019-2020
%> @copyright GNU Public License


function [meanflowL, modecL,modesL] = SF_Stability_HBN(varargin)
SF_core_log('d', '### ENTERING FUNCTION SF_HBN ');

global sfopts;
ffdatadir = sfopts.ffdatadir;

%% management of optionnal parameters
meanflowL=[]; modesL=[]; modecL=[];

meanflow = varargin{1};
mode = varargin{2};
vararginopt = varargin(3:end);
p = inputParser;
addParameter(p, 'NModes', 1);
SFcore_addParameter(p, meanflow,'Re', 1, @isnumeric); % Add Reynolds
SFcore_addParameter(p, meanflow,'Ma', 0.01, @isnumeric); % Add Mach number
SFcore_addParameter(p, meanflow,'Omegax', 0, @isnumeric); % Add rotation
addParameter(p, 'specialmode', 'normal');
% Solver parameters
addParameter(p,'type','D');
addParameter(p,'PCtype','none');
addParameter(p,'MatShell',0);
addParameter(p,'symmetry','A');
addParameter(p,'symmetryBF','S');
addParameter(p,'ncores',1);
addParameter(p, 'omegaguess', mode(1).omega);
% Eigenvalue parameters
addParameter(p, 'k', 0.0,@isnumeric);
addParameter(p, 'shift', 0, @isnumeric);
addParameter(p, 'nEig', 1);
parse(p, vararginopt{:});
NModes = p.Results.NModes;
nEig = p.Results.nEig;
Re = p.Results.Re;
ncores = p.Results.ncores;
Omegax = p.Results.Omegax;
type = p.Results.type;
% Number of guesses for harmonics
if(length(mode) == 1)
    % single mode
    Nguess = 1;
else
    Nguess = length(mode);
end

%% Position input files for FreeFem

  SFcore_MoveDataFiles(meanflow.filename,'MeanFlow_guess.txt','cp');
  SFcore_MoveDataFiles(meanflow.mesh.filename,'mesh.msh','cp');
  for i=[1:Nguess]
     SFcore_MoveDataFiles(mode(i).filename,['HBMode',num2str(i),'_guess.txt'],'cp');
  end

% Initialise parameters and arguments
ffarguments = [];
ffparameters = [];

%% definition of the solvercommand string and file names

switch (meanflow.mesh.problemtype)
    case('2D')
          ffparameters = [' '];
          % Choose the pseudo-serial or parallel FF++ bin
          if(ncores == 1)
            ffcommand = 'FreeFem++-mpi';
          else
            ffcommand = ['ff-mpirun'];
          end
          % Choose 2D or pseudo-3D FF solver
          if(p.Results.k == 0)
            ffsolver = 'Stab2D_Floquet_SLEPc_HBN.edp'; 
            bashDir = 'HBN_2D_SLEPc/';
          else
            ffsolver = 'Stab3D_Floquet_SLEPc_HBN.edp'; 
            bashDir = 'HBN_3D_SLEPc/';
            ffarguments = [ffarguments, ' -k ',num2str(p.Results.k)];
          end
          % Input arguments
          ffarguments = [ffarguments, ' -NModes ', num2str(NModes)];
          ffarguments = [ffarguments, ' -type ', num2str(type)];
          ffarguments = [ffarguments, ' -PCtype ', num2str(p.Results.PCtype)];
          ffarguments = [ffarguments, ' -MatShell ', num2str(p.Results.MatShell)];
          ffarguments = [ffarguments, ' -Re ',num2str(p.Results.Re)];
          ffarguments = [ffarguments, ' -omega ',num2str(p.Results.omegaguess)];
          ffarguments = [ffarguments, ' -nEig ',num2str(p.Results.nEig)];
          ffarguments = [ffarguments, ' -shiftr ',num2str(real(p.Results.shift))];
          ffarguments = [ffarguments, ' -shifti ',num2str(imag(p.Results.shift))];
          ffarguments = [ffarguments, ' -symmetryBaseFlow ', p.Results.symmetryBF];
          ffarguments = [ffarguments, ' -symmetry ', p.Results.symmetry]; 
          ffarguments = [ffarguments, ' -log_view -malloc_info ']; 
        % Generate FF files
        system('mkdir HBN_Stab');
        listBashFiles = {'HBM_LinOps.sh','HBM_MacroPC.sh'...
                         'HBM_2D_Fields.sh', 'HBM_2D_Parameters.sh',...
                         'HBM_2D_matLin.sh','HBM_2D_PostProcessing.sh'};
        
        for i=[1:length(listBashFiles)]
            pathToScript = fullfile(sfopts.ffdirPRIVATE,bashDir,listBashFiles{i});
            cmdStr       = char([pathToScript,' ',num2str(NModes)]); % We need char but I could not create a separated list of chars.
            status = system(cmdStr);
            if(status ~= 0)
                disp(["Error, it has not been possible to run ",...
                     listBashFiles(i)]);
                return
            end
        end
        
    
        
%    case("your case...")
        % add your case here !
        
    otherwise
        error(['Error in SF_HBN : your case ',...
              meanflow.mesh.problemtype 'is not yet implemented....'])
        
end

    
   
%% Lanch the FreeFem solver
   pause(1.0); % Maybe correct strange bug related to incompleteness of edp files
   SF_core_log('n',['#### LAUNCHING Harmonic-Balance (HBN) CALCULATION for Re = ', num2str(p.Results.Re) ' ...' ]);
   status = SF_core_freefem(ffsolver,'parameters',ffparameters,'bin',ffcommand,'arguments',ffarguments,'ncores',ncores);

   %status = mysystem(solvercommand);
   
   
   
    %% Error catching
    
     if (status==1)
         error('ERROR in SF_HBN : Freefem program failed to run  !')
     elseif (status==1)
        meanflow.iter = -1; mode.iter = -1;
        SF_core_log('e','SF_HBN : Newton iteration did not converge !')
     elseif (status==2)
        SF_core_log('w','SF_HBN : Newton iteration likely converged to steady state !')
         
     elseif(status==0)
%% Normal output
        
        SF_core_log('n',['#### HBN CALCULATION COMPLETED with Re = ',...
                    num2str(p.Results.Re)]);
        SF_core_log('n',['#### omega =  ', num2str(mode(1).omega)]);
        %%% Copies the output files into "stable" names and imports them
        for iEig=[1:nEig]
            ffmesh=meanflow.mesh;
            expectedname = ['MeanFlow',num2str(iEig),'.txt'];
            SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
            filename = SFcore_MoveDataFiles(expectedname,'MEANFLOWS');
            meanflow = SFcore_ImportData(ffmesh,filename);
            
            modes= [];
            for i=[1:NModes]
                expectedname=['HBMode',num2str(i),'s',num2str(iEig),'.txt'];
                SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
                filename = SFcore_MoveDataFiles(expectedname,'EIGENMODES');
                modeImport = SFcore_ImportData(ffmesh,filename);
                modes = [modes, modeImport];
            end
            modec= [];
            for i=[1:NModes]
                expectedname=['HBMode',num2str(i),'c',num2str(iEig),'.txt'];
                SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
                filename = SFcore_MoveDataFiles(expectedname,'EIGENMODES');
                modeImport = SFcore_ImportData(ffmesh,filename);
                modec = [modec, modeImport];
            end
            meanflowL = [meanflowL,meanflow];
            modecL = [modecL, modec];
            modesL = [modesL, modes];
        end
        
     else
         error(['ERROR in SF_HBN : return code of the FF solver is ',value]);
     end
    
end

