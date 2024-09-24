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


function [meanflow, mode] = SF_HBN(varargin)
SF_core_log('d', '### ENTERING FUNCTION SF_HBN ');

global sfopts;
ffdatadir = sfopts.ffdatadir;

%% management of optionnal parameters
meanflow = varargin{1};
mode = varargin{2};
vararginopt = varargin(3:end);
p = inputParser;
addParameter(p, 'NModes', 1);
SFcore_addParameter(p, meanflow,'Re', 1, @isnumeric); % Add Reynolds
SFcore_addParameter(p, meanflow,'Ma', 0.01, @isnumeric); % Add Mach number
SFcore_addParameter(p, meanflow,'Omegax', 0, @isnumeric); % Add rotation
addParameter(p, 'specialmode', 'normal');
addParameter(p,'PCtype','none');
addParameter(p,'symmetry','A');
addParameter(p,'symmetryBF','S');
addParameter(p,'ncores',1);
addParameter(p, 'Aguess', [-1.0]);
addParameter(p, 'Fyguess',[-1.0]);
addParameter(p, 'Amp', -1, @isnumeric);
addParameter(p, 'omegaguess', mode(1).omega);
addParameter(p, 'sigma', 0);
parse(p, vararginopt{:});
NModes = p.Results.NModes;
Re = p.Results.Re;
ncores = p.Results.ncores;
Omegax = p.Results.Omegax;
% Number of guesses for harmonics
if(length(mode) == 1)
    % single mode
    Nguess = 1;
else
    Nguess = length(mode);
end

% Parse Aguess (It should be an array with NModes components)
% Otherwise fill the rest with -1 (Do not normalise)
if(length(p.Results.Aguess) < NModes)
    nDiff = NModes-length(p.Results.Aguess);
    Aguess = p.Results.Aguess;
    for i=1:(nDiff+1)
        Aguess = [Aguess, -1];
    end
else
    Aguess = p.Results.Aguess;
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
    case({'2dcomp','2dcompsponge'})
        filenameBase = [ffdatadir 'MEANFLOWS/MeanFlow_Re' num2str(p.Results.Re),...
                            '_Ma' num2str(p.Results.Ma)];
        SF_core_log('nn', '## Entering SF_HBN (2D-COMPRESSIBLE)');
        strNormalisation = SF_HBNNormalisation(p);
        if(ncores == 1)
            pathsh='HBN_2D';
            ffparameters = [ num2str(NModes), ' ',...
                        num2str(p.Results.PCtype), ' ',...
                        num2str(p.Results.Ma), ' ',...
                        num2str(p.Results.Re), ' ',...
                        num2str(p.Results.omegaguess), ' ',...
                        num2str(p.Results.sigma), ' ',...
                        strNormalisation, ' ', p.Results.symmetryBF , ' ',...
                        p.Results.symmetry ];

            for i=1:NModes
                ffarguments = [ffarguments, ' -Eguess',num2str(i),' ',...
                               num2str(Aguess(i))];  
            end

            ffcommand = 'FreeFem++-mpi';
            ffsolver = 'HBN_2D_Comp.edp'; 
            shCodeGeneratorAxiComp(pathsh,NModes);
        else
            pathsh='HBN_2D_mpi';
            ffcommand = ['ff-mpirun'];
            ffsolver = 'MPIHBN_2D_Comp.edp'; 
            ffarguments = [ffarguments, ' -NModes ', num2str(NModes)];
            ffarguments = [ffarguments, ' -PCtype ', num2str(p.Results.PCtype)];
            ffarguments = [ffarguments, ' -Ma ',num2str(p.Results.Ma)];
            ffarguments = [ffarguments, ' -Re ',num2str(p.Results.Re)];
            ffarguments = [ffarguments, ' -omega ',num2str(p.Results.omegaguess)];
            ffarguments = [ffarguments, ' -sigma ',num2str(p.Results.sigma)];
            ffarguments = [ffarguments, ' -normalisation ',strNormalisation];
            ffarguments = [ffarguments, ' -symmetryBaseFlow ', p.Results.symmetryBF];
            ffarguments = [ffarguments, ' -symmetry ', p.Results.symmetry];
            ffparameters = [' '];
            for i=1:NModes
                ffarguments = [ffarguments, ' -Eguess',num2str(i),' ',...
                               num2str(Aguess(i))];  
            end
            shCodeGeneratorAxiComp(pathsh,NModes);
        end
                     
    case({'axicompcomplex','axicompsponge'})
        filenameBase = [ffdatadir 'MEANFLOWS/MeanFlow_Re' num2str(p.Results.Re),...
                            '_Ma' num2str(p.Results.Ma)];
        SF_core_log('nn', '## Entering SF_HBN (Axi-COMPRESSIBLE)');
        strNormalisation = SF_HBNNormalisation(p);
        if(ncores == 1)
            pathsh='HBN_2D';
            ffparameters = [ num2str(NModes), ' ',...
                        num2str(p.Results.PCtype), ' ',...
                        num2str(p.Results.Ma), ' ',...
                        num2str(p.Results.Re), ' ',...
                        num2str(p.Results.omegaguess), ' ',...
                        num2str(p.Results.sigma), ' ',...
                        strNormalisation, ' ', p.Results.symmetryBF , ' ',...
                        p.Results.symmetry ];

            for i=1:NModes
                ffarguments = [ffarguments, ' -Eguess',num2str(i),' ',...
                               num2str(Aguess(i))];  
            end

            ffcommand = 'FreeFem++-mpi';
            ffsolver = 'HBN_Axi_Comp.edp'; 
            shCodeGeneratorAxiComp(pathsh,NModes);
        else
            pathsh='HBN_2D_mpi';
            ffcommand = ['ff-mpirun'];
            ffsolver = 'MPIHBN_Axi_Comp.edp'; 
            ffarguments = [ffarguments, ' -NModes ', num2str(NModes)];
            ffarguments = [ffarguments, ' -PCtype ', num2str(p.Results.PCtype)];
            ffarguments = [ffarguments, ' -Ma ',num2str(p.Results.Ma)];
            ffarguments = [ffarguments, ' -Re ',num2str(p.Results.Re)];
            ffarguments = [ffarguments, ' -omega ',num2str(p.Results.omegaguess)];
            ffarguments = [ffarguments, ' -sigma ',num2str(p.Results.sigma)];
            ffarguments = [ffarguments, ' -normalisation ',strNormalisation];
            ffarguments = [ffarguments, ' -symmetryBaseFlow ', p.Results.symmetryBF];
            ffarguments = [ffarguments, ' -symmetry ', p.Results.symmetry];
            ffparameters = [' '];
            for i=1:NModes
                ffarguments = [ffarguments, ' -Eguess',num2str(i),' ',...
                               num2str(Aguess(i))];  
            end
            shCodeGeneratorAxiComp(pathsh,NModes);
        end
        
    
    case('2D')
          strNormalisation = SF_HBNNormalisation(p);
          ffparameters = [' '];
          if(ncores == 1)
            ffcommand = 'FreeFem++-mpi';
          else
            ffcommand = ['ff-mpirun'];
          end
          ffsolver = 'HBN_2D.edp'; 
          ffarguments = [ffarguments, ' -NModes ', num2str(NModes)];
          ffarguments = [ffarguments, ' -PCtype ', num2str(p.Results.PCtype)];
          ffarguments = [ffarguments, ' -Re ',num2str(p.Results.Re)];
          ffarguments = [ffarguments, ' -omega ',num2str(p.Results.omegaguess)];
          ffarguments = [ffarguments, ' -sigma ',num2str(p.Results.sigma)];
          ffarguments = [ffarguments, ' -normalisation ',strNormalisation];
          ffarguments = [ffarguments, ' -symmetryBaseFlow ', p.Results.symmetryBF];
          ffarguments = [ffarguments, ' -symmetry ', p.Results.symmetry];
          for i=1:NModes
                ffarguments = [ffarguments, ' -Eguess',num2str(i),' ',...
                               num2str(Aguess(i))];  
            end
      if( strcmp(p.Results.PCtype,'none') || strcmp(p.Results.PCtype,'bjacobi') )
      else
          error(['MATLAB DRIVER ERROR: PC not yet implemented....']);
      end       
      
        filenameBase = [ffdatadir 'MEANFLOWS/MeanFlow_Re' num2str(Re),...
                        '_Omegax' num2str(Omegax)];
        system('mkdir HBN');
        listBashFiles = {'HBM_LinOps.sh', 'HBM_NLOps.sh',...
                         'HBM_2D_Fields.sh', 'HBN_2D_Parameters.sh',...
                         'HBM_2D_matLin.sh', 'HBM_RHS.sh',...
                         'HBM_MacroPC.sh', 'HBM_2D_PCLU.sh',...
                         'HBM_2D_LinOpPCNone.sh', 'HBM_2D_Newton_out.sh'...
                         'HBM_2D_PostProcessing.sh', 'HBM_2D_Newton_Conv.sh'};
        
        for i=[1:length(listBashFiles)]
            pathToScript = fullfile(sfopts.ffdirPRIVATE,'HBN_2D/',listBashFiles{i});
            cmdStr       = char([pathToScript,' ',num2str(NModes)]); % We need char but I could not create a separated list of chars.
            status = system(cmdStr);
            if(status ~= 0)
                disp(["Error, it has not been possible to run ",...
                     listBashFiles(i)]);
                return
            end
        end
        
    case('2DPETSc')
          strNormalisation = SF_HBNNormalisation(p);
          ffparameters = [' '];
          if(ncores == 1)
            ffcommand = 'FreeFem++-mpi';
          else
            ffcommand = ['ff-mpirun'];
          end
          pathsh='HBN_2D_PETSc';
          ffsolver = 'HBN_2D_PETSc.edp'; 
          ffarguments = [ffarguments, ' -NModes ', num2str(NModes)];
          ffarguments = [ffarguments, ' -PCtype ', num2str(p.Results.PCtype)];
          ffarguments = [ffarguments, ' -Re ',num2str(p.Results.Re)];
          ffarguments = [ffarguments, ' -omega ',num2str(p.Results.omegaguess)];
          ffarguments = [ffarguments, ' -sigma ',num2str(p.Results.sigma)];
          ffarguments = [ffarguments, ' -normalisation ',strNormalisation];
          ffarguments = [ffarguments, ' -symmetryBaseFlow ', p.Results.symmetryBF];
          ffarguments = [ffarguments, ' -symmetry ', p.Results.symmetry];
          ffparameters = [' '];
            for i=1:NModes
                ffarguments = [ffarguments, ' -Eguess',num2str(i),' ',...
                               num2str(Aguess(i))];  
            end
          if( strcmp(p.Results.PCtype,'none') || strcmp(p.Results.PCtype,'bjacobi') )
          else
              error(['MATLAB DRIVER ERROR: PC not yet implemented....']);
          end       
          system('mkdir HBN');
          shCodeGeneratator2DPETSc(pathsh,NModes);

        
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
        ffmesh=meanflow.mesh;
        expectedname = ['MeanFlow.txt'];
        SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
        filename = SFcore_MoveDataFiles(expectedname,'MEANFLOWS');
        meanflow = SFcore_ImportData(ffmesh,filename);

        mode= [];
        for i=[1:NModes]
            expectedname=['HBMode',num2str(i),'.txt'];
            SFcore_AddMESHFilenameToFF2M(expectedname,ffmesh.filename);
            filename = SFcore_MoveDataFiles(expectedname,'EIGENMODES');
            modeImport = SFcore_ImportData(ffmesh,filename);
            mode = [mode, modeImport];
        end
        
     else
         error(['ERROR in SF_HBN : return code of the FF solver is ',value]);
     end
    
end

function shCodeGeneratorAxiComp(path,NModes)
    global sfopts;
    system('mkdir HBN');
    listBashFiles = {'HBM_2DComp_Fields.sh',...
                            'HBM_2DComp_LinOpPCNone.sh',...
                            'HBM_2DComp_LinOps.sh',...
                            'HBM_2DComp_matLin.sh',...
                            'HBM_2DComp_matLinNOPC.sh',...
                            'HBM_2DComp_Newton_Conv.sh',...
                            'HBM_2DComp_Newton_out.sh',...
                            'HBM_2DComp_Newton_outNOPC.sh',...
                            'HBM_2DComp_NLOps.sh',...
                            'HBM_2DComp_Parameters.sh',...
                            'HBM_2DComp_PostProcessing.sh',...
                            'HBM_2DComp_RHS.sh',...
                            'HBM_2DComp_RHSNOPC.sh',...
                            'HBM_2DComp_MacroPC.sh',...
                            'HBM_2DComp_PCLU.sh'};
    for i=[1:length(listBashFiles)]
                pathToScript = fullfile(sfopts.ffdirPRIVATE,path,'/',listBashFiles{i});
                cmdStr       = char([pathToScript,' ',num2str(NModes)]); % We need char but I couldn't create a separated list of chars.
                status = system(cmdStr);
                if(status ~= 0)
                    disp(["Error, it has not been possible to run ",...
                         listBashFiles(i)]);
                    return
                end
            end
end


function shCodeGeneratator2DPETSc(path,NModes)
    global sfopts;
    system('mkdir HBN');
    listBashFiles = {'HBM_2D_Fields.sh',...
                    'HBM_2D_matLin.sh',...
                    'HBM_2D_Newton_Conv.sh',...
                    'HBM_2D_Newton_out.sh',...
                    'HBM_2D_Parameters.sh',...
                    'HBM_LinOps.sh',...
                    'HBM_NLOps.sh',...
                    'HBM_RHS.sh',...
                    'HBM_2D_PostProcessing.sh'};
    for i=[1:length(listBashFiles)]
        pathToScript = fullfile(sfopts.ffdirPRIVATE,path,'/',listBashFiles{i});
        cmdStr       = char([pathToScript,' ',num2str(NModes)]); % We need char but I couldn't create a separated list of chars.
        status = system(cmdStr);
        if(status ~= 0)
            disp(["Error, it has not been possible to run ",...
                 listBashFiles(i)]);
            return
        end
    end
end

function strNormalisation = SF_HBNNormalisation(structParsed)
    if (structParsed.Results.Fyguess ~= -1)
                mydisp(2,['starting with guess Lift force : ',...
                       num2str(structParsed.Results.Fyguess)]);
                strNormalisation = 'L';
            elseif (structParsed.Results.Aguess ~= -1.0)
                mydisp(2,['starting with guess amplitude of mode 1 (Energy) ',...
                       num2str(structParsed.Results.Aguess(1))]);
                strNormalisation = 'E';
            else
                strNormalisation = 'none';
    end
end


