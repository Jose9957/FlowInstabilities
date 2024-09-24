
function [meanflow, mode] = SF_HB1(meanflow, mode, varargin)
%> StabFem wrapper for Harmonic Balance order 1 (idem as Self-Consistent model of Mantic lugo et al.)
%>
%> usage : [meanflow,mode] = SF_HB1(meanflow,mode,[Param1, Value1,...])
%>
%> first argument is either a "baseflow" or a "meanflow"
%> second argument is either an "eigenmode" or a "harmonicmode".
%>
%> Parameters include :
%>
%>   Re :        Reynolds number (specify only if it differs from the one of base flow, which is not usual)
%>   Aguess :    Amplitude for renormalising the eigenmode/SCmode
%>   Fyguess :   Lift for renormalising the eigenmode/SCmode
%>   (if none of these is present then no renormalization is done)
%>   omegaguess : guess for frequency (if not provided we take the im. part of the eigenvalue of the mode)
%>   sigma  :    instantaneous growth rate (nonzero for SC model ; zero for HB model)
%>   specialmode :  if value is 'NEW', recomputation will be forced even if result files seems to be already present
%>
%>  Copyright D. Fabre, 2018
%>
%> NOTE (DF, april 6 2019) 
%>      I HAVE DISABLED THE AUTOMATIC RECOVERY IF FILES ALREADY EXIST. 
%>      THIS IS TO BE REDONE IN A BETTER WAY

ffdatadir = SF_core_getopt('ffdatadir');

%% management of optionnal parameters : definition and default values
p = inputParser;
addParameter(p, 'Re', meanflow.Re, @isnumeric);
addParameter(p, 'Ma', 0.4, @isnumeric);
addParameter(p, 'Omegax', 0, @isnumeric);
addParameter(p, 'Aguess', -1, @isnumeric);
addParameter(p, 'Fyguess', -1, @isnumeric);
addParameter(p, 'Amp', -1, @isnumeric);
addParameter(p, 'omegaguess', imag(mode.lambda));
addParameter(p, 'sigma', 0);
addParameter(p, 'specialmode', 'normal');
addParameter(p,'symmetry','A');
addParameter(p,'symmetryBF','S');
parse(p, varargin{:});
Re  = p.Results.Re;
%% Position input files

  
%   SFcore_MoveDataFiles(meanflow.filename,'MeanFlow_guess.txt','cp');
  SFcore_MoveDataFiles(meanflow.filename,'BaseFlow.txt','cp');
  SFcore_MoveDataFiles(meanflow.mesh.filename,'mesh.msh','cp');
  SFcore_MoveDataFiles(mode.filename,'HBMode1_guess.txt','cp');

%% definition of the solvercommand string and file names

switch (meanflow.mesh.problemtype)
    
    case('2D')
        if(p.Results.Amp ~= -1)
            AMP = p.Results.Amp;
        elseif (p.Results.Fyguess ~= -1)
            mydisp(2,['starting with guess Lift force : ', num2str(p.Results.Fyguess)]);
            AMP = p.Results.Fyguess/mode.Fy;
        elseif (p.Results.Aguess ~= -1)
            mydisp(2,['starting with guess amplitude (Energy) ', num2str(p.Results.Aguess)]);
            AMP = p.Results.Aguess/mode.Aenergy;
        else
            AMP = 1;
        end
        
         ffparameters = [num2str(p.Results.Re), ' ', num2str(p.Results.Omegax), ' ', num2str(p.Results.omegaguess), ' ', ...
             num2str(p.Results.sigma),' ',num2str(real(AMP)), ' ', num2str(imag(AMP)), ' ', p.Results.symmetryBF , ' ', p.Results.symmetry ];
         ffsolver =  'HB1_2D.edp';
        
        Re = p.Results.Re;
%        if exist([ffdatadir 'MEANFLOWS'],'dir')==0
%            mymake([ffdatadir 'MEANFLOWS'])
%        end
     
    case({'2dcompsponge','2dcomp'})
        
        if (p.Results.Fyguess ~= -1)
            mydisp(2,['starting with guess Lift force : ', num2str(p.Results.Fyguess)]);
            AMP = p.Results.Fyguess/mode.Fy;
            MODE = 'L';
        elseif (p.Results.Aguess ~= -1)
            mydisp(2,['starting with guess amplitude (Energy) ', num2str(p.Results.Aguess)]);
            AMP = p.Results.Aguess;
            MODE = 'E';
        else
            AMP = 1;
            MODE = 'none';
        end
        ffparameters = [num2str(p.Results.Ma), ' ', num2str(p.Results.Re), ' ', num2str(p.Results.omegaguess), ' ', num2str(p.Results.sigma), ...
                      ' ', MODE, ' ', p.Results.symmetryBF , ' ', p.Results.symmetry, ' ' num2str(real(AMP)) ];
        ffsolver =  'HB1_2DComp.edp';  
        % case("your case...")
        % add your case here !
    case({'axicompcomplex','axicompsponge'})
        
        if (p.Results.Fyguess ~= -1)
            mydisp(2,['starting with guess Lift force : ', num2str(p.Results.Fyguess)]);
            AMP = p.Results.Fyguess/mode.Fy;
            MODE = 'L';
        elseif (p.Results.Aguess ~= -1)
            mydisp(2,['starting with guess amplitude (Energy) ', num2str(p.Results.Aguess)]);
            AMP = p.Results.Aguess;
            MODE = 'E';
        else
            AMP = 1;
            MODE = 'none';
        end
        ffparameters = [num2str(p.Results.Ma), ' ', num2str(p.Results.Re), ' ', num2str(p.Results.omegaguess), ' ', num2str(p.Results.sigma), ...
                      ' ', MODE, ' ', p.Results.symmetryBF , ' ', p.Results.symmetry, ' ' num2str(real(AMP)) ];
        ffsolver =  'HB1_AxiComp.edp';  
        % case("your case...")
        % add your case here !
                
    otherwise
        error(['Error in SF_HB1 : your case ', meanflow.mesh.problemtype 'is not yet implemented....'])
        
end

%% disabled section
%if(exist([filenameBase '.txt'])==2)&&(exist([filenameHB1 '.txt'])==2)...
%    &&(exist([filenameHB2 '.txt'])==0)&&(strcmpi(p.Results.specialmode,'NEW')==0)&&(p.Results.sigma==0)
%    
%    %%% Recover results from a previous calculation
%    mydisp(1,['#### Self-Consistent (HB1) CALCULATION seems to be previously done... recover files ...' ]);
%    meanflow = SFcore_ImportData(meanflow.mesh,[filenameBase '.ff2m']);
%    mode = SFcore_ImportData(meanflow.mesh,[filenameHB1 '.ff2m']);
    
%else
    
%%
% Lanch the FreeFem solver
    SF_core_log('n',['#### LAUNCHING Self-Consistent (HB1) CALCULATION for Re = ', num2str(p.Results.Re) ' ...' ]);
%    status = mysystem(solvercommand);
    status = SF_core_freefem(ffsolver,'parameters',ffparameters);
    
    
    %% Error catching
    
     if (status==1)
         error('ERROR in SF_HH1 : Freefem program failed to run  !')
     elseif (status==1)
        meanflow.iter = -1; mode.iter = -1; 
        SF_core_log('e','SF_HB1 : Newton iteration did not converge !')
     elseif (status==2)
        SF_core_log('w','SF_HB1 : Newton iteration likely converged to steady state !')
         
     elseif(status==0)
%% Normal output
        
        SF_core_log('n',['#### Self-Consistent (HB1) CALCULATION COMPLETED with Re = ', num2str(p.Results.Re), ' ; sigma = ', num2str(p.Results.sigma)]);
        SF_core_log('n',['#### omega =  ', num2str(imag(mode.lambda))]);
        
%%% Copies the output files into "stable" names and imports them
        filenameBase = [ffdatadir 'MEANFLOWS/MeanFlow_Re' num2str(Re) '_Omegax' num2str(p.Results.Omegax)];
        filenameHB1 = [ffdatadir 'MEANFLOWS/HBMode1_Re' num2str(Re) '_Omegax' num2str(p.Results.Omegax)];
        filenameHB2 = [ffdatadir 'MEANFLOWS/HBMode2_Re' num2str(Re) '_Omegax' num2str(p.Results.Omegax)];% this one should not be present
        
        SFcore_AddMESHFilenameToFF2M('MeanFlow.txt',meanflow.mesh.filename);
        newname = SFcore_MoveDataFiles('MeanFlow.txt',[filenameBase '.txt']);
        meanflow = SFcore_ImportData(meanflow.mesh,newname);
        
        SFcore_AddMESHFilenameToFF2M('HBMode1.txt',meanflow.mesh.filename);
        newname = SFcore_MoveDataFiles('HBMode1.txt',[filenameHB1 '.txt']);
        mode = SFcore_ImportData(meanflow.mesh,newname);
        
        myrm(filenameHB2); % to avoid possible bad interaction with HB2 
        
    else
        error(['ERROR in SF_HB1 : return code of the FF solver is ',status]);
    end
    % eventually clean working directory from temporary files
    SF_core_arborescence('cleantmpfiles') 
    SF_core_log('d', '### END FUNCTION SF_HB1');
end


