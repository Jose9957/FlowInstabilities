
function [meanflow, mode, mode2] = SF_HB2(varargin)
%> StabFem wrapper for Harmonic Balance order 2
%>
%> usage : 
%> 1. [meanflow,mode,mode2] = SF_HB1(meanflow,mode,mode2,'Re',Re)
%>
%> 2. [meanflow,mode,mode2] = SF_HB1(meanflow,mode,'Re',Re)
%>                    (variant to start from HB1 results)
%>
%> first argument is either a "baseflow" or 'meanflow"
%> second argument is either an "eigenmode" or a "selfconsistentmode".
%> third argument is a 'SecondHarmonicMode'.
%>
%> Parameters include :
%>
%>   Re :        Reynolds number (specify only if it differs from the one of base flow, which is not usual)
%>
%>  Copyright D. Fabre, 2018
%> 
%> NOTE (DF, april 6 2019) 
%>      I HAVE DISABLED THE AUTOMATIC RECOVERY IF FILES ALREADY EXIST. 
%>      THIS IS TO BE REDONE IN A BETTER WAY

ffdatadir = SF_core_getopt('ffdatadir') % to be removed soon

%% management of optionnal parameters
meanflow = varargin{1};
mode = varargin{2};
if(nargin>2&&isstruct(varargin{3}))
    mode2 = varargin{3};
    vararginopt = varargin(4:end);
else
    mode2 = -1;
    vararginopt = varargin(3:end);
end
p = inputParser;
addParameter(p, 'Re', meanflow.Re, @isnumeric);
addParameter(p, 'Omegax', 0, @isnumeric);
addParameter(p, 'specialmode', 'normal');
addParameter(p,'symmetry','A');
addParameter(p,'symmetryBF','S');
parse(p, vararginopt{:});
Re = p.Results.Re;
Omegax = p.Results.Omegax;

%% Position input files for FreeFem

  SFcore_MoveDataFiles(meanflow.filename,'MeanFlow_guess.txt','cp');
  SFcore_MoveDataFiles(meanflow.mesh.filename,'mesh.msh','cp');
  SFcore_MoveDataFiles(mode.filename,'HBMode1_guess.txt','cp');

if ~isnumeric(mode2)
    SFcore_MoveDataFiles(mode2.filename, 'HBMode2_guess.txt');
else
    SF_core_syscommand('rm','HBMode2_guess.txt');
end


%% definition of the solvercommand string and file names

switch (meanflow.mesh.problemtype)
    
    case('2D')
      %  solvercommand = ['echo ', num2str(p.Results.Re), ' ' p.Results.symmetry ' | ', ff, ' ', ffdir, 'HB2_2D.edp'];        
      %  Re = p.Results.Re;
      
       ffparameters = [num2str(p.Results.Re), ' ',num2str(p.Results.Omegax), ' ', p.Results.symmetryBF, ' ' p.Results.symmetry];
       ffsolver =  'HB2_2D.edp';
      
        filenameBase = [ffdatadir 'MEANFLOWS/MeanFlow_Re' num2str(Re),'_Omegax' num2str(Omegax)];
        filenameHB1 =  [ffdatadir 'MEANFLOWS/Harmonic1_Re' num2str(Re),'_Omegax' num2str(Omegax)];
        filenameHB2 =  [ffdatadir 'MEANFLOWS/Harmonic2_Re' num2str(Re),'_Omegax' num2str(Omegax)];
        
%    case("your case...")
        % add your case here !
        
    otherwise
        error(['Error in SF_HB2 : your case ', meanflow.mesh.problemtype 'is not yet implemented....'])
        
end

%% disabled section
%if(exist([filenameBase '.txt'])==2)&&(exist([filenameHB1 '.txt'])==2)&&(exist([filenameHB2 '.txt'])==2)&&(strcmp(p.Results.specialmode,'NEW')==0)
        %%% Recover results from a previous calculation
%    mydisp(1,['#### HB2 CALCULATION for Re = ' num2str(Re) ' seems to be previously done... recover files ...' ]);
%    meanflow = SFcore_ImportData(meanflow.mesh,[filenameBase '.ff2m']);
%    mode = SFcore_ImportData(meanflow.mesh,[filenameHB1 '.ff2m']);
%    mode2 = SFcore_ImportData(meanflow.mesh,[filenameHB2 '.ff2m']);
    
%else
    
   
%% Lanch the FreeFem solver
   SF_core_log('n',['#### LAUNCHING Harmonic-Balance (HB2) CALCULATION for Re = ', num2str(p.Results.Re) ' ...' ]);
   status = SF_core_freefem(ffsolver,'parameters',ffparameters);

   %status = mysystem(solvercommand);
   
   
   
    %% Error catching
    
     if (status==1)
         error('ERROR in SF_HB2 : Freefem program failed to run  !')
     elseif (status==1)
        meanflow.iter = -1; mode.iter = -1;mode2.iter = -1;
        SF_core_log('e','SF_HB2 : Newton iteration did not converge !')
     elseif (status==2)
        SF_core_log('w','SF_HB2 : Newton iteration likely converged to steady state !')
         
     elseif(status==0)
%% Normal output
        
        SF_core_log('n',['#### HB2 CALCULATION COMPLETED with Re = ', num2str(p.Results.Re)]);
        SF_core_log('n',['#### omega =  ', num2str(imag(mode.lambda))]);
        
        %%% Copies the output files into "stable" names and imports them
        newname = SFcore_MoveDataFiles('MeanFlow.txt',[filenameBase '.txt']);
        meanflow = SFcore_ImportData(meanflow.mesh,newname);
        
        newname = SFcore_MoveDataFiles('HBMode1.txt',[filenameHB1 '.txt']);
        mode = SFcore_ImportData(meanflow.mesh,newname);

        newname = SFcore_MoveDataFiles('HBMode2.txt',[filenameHB2 '.txt']);
        mode2 = SFcore_ImportData(meanflow.mesh,newname);
        
     else
         error(['ERROR in SF_HB2 : return code of the FF solver is ',value]);
     end
    SF_core_arborescence('cleantmpfiles')     
    SF_core_log('d', '### END FUNCTION SF_HB2');
end
