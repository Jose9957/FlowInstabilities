function res = SF_LinearForced(bf,varargin)
%>
%> Function SF_LinearForced
%>
%> This function solves a linear, forced problem for a single value of
%> omega or for a range of omega (for instance impedance computations)
%>
%> Usage :
%> 1/ res = SF_LinearForced(bf,'omega',omega) (single omega mode)
%>      in this case res will be a flowfield structure 
%> 
%>  2/ res = SF_LinearForced(bf,'omega',omega) (loop-omega mode)
%>      in this case res will be a structure composed of arrays, as specified in the Macro_StabFem.edp 
%>      (for instance omega and Z)
%>
%>  Parameters : 'plot',true => the program will plot the impedance and
%>                               Nyquist diagram
%>  Parameters : 'BC','SOMMERFELD' => Boundary condition for the farfield
%>                                    for the acoustic simulations 
%>
%> Copyright D. Fabre, 11 oct 2018
%> This program is part of the StabFem project distributed under gnu licence.

persistent counter 
if isempty(counter)
    counter = 0;
end
persistent solverprevious;


 if isfield(bf,'iter')&&bf.iter<0
     SF_core_log('w' ,' baseflow.iter < 0 ! it seems your previous baseflow computation diverged !');
 elseif isfield(bf,'iter')&&bf.iter==0
     SF_core_log('w' ,' baseflow.iter = 0 ! it seems your baseflow was projected after mesh adaptation but not recomputed !');
 end


if (mod(length(varargin),2)==1) 
    SF_core_log('l','SF_LinearForced : recommended to use [''Omega'',omega] in list of arguments ');  
    varargin = ['omega',varargin];
end
    
   p = inputParser;
   addParameter(p,'omega',1); 
   addParameter(p,'plot',false);
   
   addParameter(p,'solver','default');
   addParameter(p,'BC','SOMMERFELD',@ischar);
   addParameter(p, 'MappingDef', 'none'); % Array of parameters for the cases involving mapping
   addParameter(p, 'MappingParams', 'default'); % Array of parameters for the cases involving mapping

   addParameter(p,'Options',''); % string of options e.g. '-NsF 30'
   
   parse(p,varargin{:});

   omega = p.Results.omega;

% Creating mapping if needed (even if no mapping we need to recreate the file !)
        SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams);
   
% Position input files
if(strcmpi(bf.datatype,'Mesh')==1)
       % first argument is a simple mesh
       ffmesh = bf; 
       SFcore_MoveDataFiles(ffmesh.filename,'mesh.msh','cp'); 
else
       % first argument is a base flow
       ffmesh = bf.mesh;
       SFcore_MoveDataFiles(bf.filename,'BaseFlow.txt','cp');
       SFcore_MoveDataFiles(bf.mesh.filename,'mesh.msh','cp'); 
end

arguments = p.Results.Options;

switch lower(ffmesh.problemtype)

        case('unspecified')
            % New generic interface
        paramstring = [' array ' num2str(length(omega))]; % ne sert a rien pour cas Nabil
        if ~strcmp(p.Results.solver,'default')
            solver = p.Results.solver;
            SF_core_log('nn',['## SF_LinearForced : using Newton solver ',p.Results.solver]);
            solverprevious = solver;
        elseif ~isempty(solverprevious)
            SF_core_log('nn',['## Entering SF_LinearForced : using (previously specified) Newton solver ',solverprevious]);
           solver = solverprevious;
        else
            SF_core_log('e','ERROR : You must either specify a solver when calling SF_LinearForced or specify a problemtype when creating mesh');    
        end 
    
        if ~strcmp(p.Results.MappingDef,'none')
            SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams);
            SF_core_log('n','Using complex mapping');
        end
    case({'axixr','axixrcomplex'}) % Jet sifflant Axi Incomp.
        if strcmp(p.Results.MappingDef,'none')
            solver = 'LinearForcedAxi_m0.edp';
        else
            SFcore_CreateMappingParamFile(p.Results.MappingDef,p.Results.MappingParams);
            solver = 'LinearForcedAxi_COMPLEX_m0.edp';
        end
        paramstring = [' array ' num2str(length(omega))];
        
%    case('axixrcomplex')
%        solver = [ 'LinearForcedAxi_COMPLEX_m0.edp'];
%        FFfilename = [ffdatadir 'Field_Impedance_Re' num2str(bf.Re) '_Omega' num2str(omega(1))];
%        FFfilenameStat = [ffdatadir 'Impedances_Re' num2str(bf.Re)];
%        paramstring = [' array ' num2str(length(omega))];    
    
    

    case({'2d','2dmobile'}) % VIV
        solver = 'LinearForced2D.edp';
        paramstring = [' array ' num2str(length(omega))];
        if isfield(bf.mesh,'symmetry')&&strcmp(bf.mesh.symmetry,'S')
            SF_core_log('n','detected half-mesh and symmetric BF, perturbation is expected antisymmetric');
            arguments = [arguments, ' -Symmetry A'];
        end
        
    case('acousticaxi') % Acoustic-Axi (Helmholtz).
        if strcmpi(p.Results.BC,'sommerfeld')
            solver = 'LinearForcedAcoustic.edp';
        else
            solver = 'LinearForcedAcoustic_CM.edp';
        end
        paramstring = [' array ' num2str(length(omega))];
         arguments = [arguments, ' -BC ',p.Results.BC];
    otherwise
        SF_core_log('e',['Error in SF_LinearForced : problemtype ' ffmesh.problemtype ' not recognized']);
end

if(strcmp(p.Results.solver,'default'))
    SF_core_log('n',['      ### USING standart StabFem Solver for this class of problems : ',solver]);        
else
    solver = p.Results.solver;
    SF_core_log('n',['      ### USING specified FreeFem++ Solver ',solver]);
end 

for i=1:length(omega)
    paramstring = [paramstring ' ' num2str(real(omega(i))),' ',num2str(imag(omega(i))) ];
end

    binary = 'default'; 
    SF_core_freefem(solver,'parameters',paramstring,'bin',binary,'arguments',arguments);
 
 if(length(omega)==1)
    SFcore_AddMESHFilenameToFF2M('ForcedFlow.ff2m',ffmesh.filename);    
    %newfilename = SFcore_MoveDataFiles('ForcedFlow.ff2m',['FORCEDFLOWS/',FFfilename, '.ff2m']);
    newfilename = SFcore_MoveDataFiles('ForcedFlow.ff2m','FORCEDFLOWS/');
    res = SFcore_ImportData(ffmesh,newfilename);
    
 else
   %newfilename = SFcore_MoveDataFiles('LinearForcedStatistics.ff2m',['FORCEDSTATS/',FFfilenameStat,'.ff2m']); % not sure where to put it    
   newfilename = SFcore_MoveDataFiles('LinearForcedStatistics.ff2m','IMPEDANCES');
   res = SFcore_ImportData(ffmesh,newfilename);
    
    % if complex data is included reconstruct it here (to be improved)
        if(isfield(res,'Z_r'))
            res.Z = res.Z_r+1i*res.Z_i;
            res.omega = res.omega_r;
        end
         if(isfield(res,'Zr'))
            res.Z = res.Zr+1i*res.Zi;
        end
    
    %plots... (obsolete section)
    if p.Results.plot
        figure(101);hold on;
        mycolors = 'brgcmk'; 
        thecolor = mycolors(mod(counter,6)+1);
        counter = counter+1;
        %if strcmp(p.Results.PlotSpectrumSymbol,'')
            theplotsymbol = [thecolor,'+'];
        %else
        %    theplotsymbol = p.Results.PlotSpectrumSymbol;
        %end
        
    
    if(strcmpi(ffmesh.problemtype,'axicomplex'))
    subplot(1,2,1); hold on;
    plot(res.omega,real(res.Z),[theplotsymbol,'-'],res.omega,-imag(res.Z)./res.omega,[theplotsymbol,'--']);hold on;
    plot(res.omega,0*real(res.Z),'k:','LineWidth',1)
    xlabel('\omega');ylabel('Z_r, -Z_i/\omega');
    title(['Impedance for Re = ',num2str(bf.Re)] );
    subplot(1,2,2);hold on;
    plot(real(res.Z),imag(res.Z),[theplotsymbol,'-']); title(['Nyquist diagram for Re = ',num2str(bf.Re)] );
    xlabel('Z_r');ylabel('Z_i');ylim([-10 2]);
    box on; pos = get(gcf,'Position'); pos(4)=pos(3)*.5;set(gcf,'Position',pos);
    pause(0.1);
    end
  
    if(strcmpi(ffmesh.problemtype,'2d'))
    subplot(1,2,1); hold on;
    plot(res.omega/(2*pi),real(res.Z),[theplotsymbol,'-'],res.omega/(2*pi),imag(res.Z),[theplotsymbol,'--']);hold on;
    plot(res.omega/(2*pi),0*real(res.Z),'k:','LineWidth',1)
    xlabel('St');ylabel('Z_r, Z_i');
    title(['Impedance for Re = ',num2str(bf.Re)] );
    subplot(1,2,2);hold on;
    plot(real(res.Z),imag(res.Z),[theplotsymbol,'-']); title(['Nyquist diagram for Re = ',num2str(bf.Re)] );
    xlabel('Z_r');ylabel('Z_i');
    box on; pos = get(gcf,'Position'); pos(4)=pos(3)*.5;set(gcf,'Position',pos);
    pause(0.1);
    end
    hold off;
    end    
 end
 

 % eventually clean working directory from temporary files
% SF_core_arborescence('cleantmpfiles')
 
  
SF_core_log('d', '### END FUNCTION SF_LinearForced ');
 
end