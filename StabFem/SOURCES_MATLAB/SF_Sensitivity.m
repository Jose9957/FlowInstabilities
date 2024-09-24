function [sensitivity] = SF_Sensitivity(baseflow, eigenmodeD, eigenmodeA, varargin)
%>
%> StabFem driver/computer for Structural sensitivity.
%> 
%> USAGE : sensitivity = SF_Sensitivity(baseflow, eigenmodeD, eigenmodeA, [optional parameters..])
%> 
%> Depending upon the cases, calculation is done either by invoking a
%> case-dependent FreeFem solver, or directly within this function.
%>
%> Currently implemented : 2D (direct calculation) ; 2D-comp (FreeFem solver)



%global sfopts;
%ff = 'FreeFem++';
%ffMPI = 'FreeFem++-mpi';
%ffdir = sfopts.ffdir;
%ffdatadir = sfopts.ffdatadir;
%


%% Parse variable inputs
p = inputParser;

addParameter(p, 'solver','none'); % Mode selection

SFcore_addParameter(p, baseflow,'Re', 1, @isnumeric); % Reynolds
%if (isfield(baseflow,'Ma')) // JAVIER this if/else is done within
%SFcore_addParameter !
%   SFcore_addParameter(p, baseflow,'Mach', baseflow.Ma, @isnumeric); % Mach
%else
    SFcore_addParameter(p, baseflow,'Ma', 0.01, @isnumeric); % Mach
%end
%if (isfield(eigenmodeD,'k'))
%   SFcore_addParameter(p, eigenmodeD,'k', eigenmodeD.k, @isnumeric); % k
%else
    SFcore_addParameter(p, eigenmodeD,'k', 0, @isnumeric); % spanwise waven
%end
addParameter(p, 'Type','S'); % Mode selection
addParameter(p, 'problemtype',''); 

parse(p, varargin{:});


if ~isempty(p.Results.problemtype)
    problemtype = p.Results.problemtype;
else
    problemtype = baseflow.mesh.problemtype;
end

%% Selects the right solver
switch(lower(problemtype))
    case('unspecified')
        ffsolver = p.Results.solver;
        ffparams = '';
        SF_core_log('n', ['## Entering SF_Sensitivity (new generic interface) with specified solver ',ffsolver]);
        
    case('2dcomp')
        SF_core_log('n', '## Entering SF_Sensitivity (2D-Compressible)');
        ffparams = [ num2str(p.Results.Re), ' ',...
            num2str(p.Results.Ma), ' ', p.Results.Type, ' ', ...
            baseflow.mesh.symmetry, ' ', num2str(p.Results.k)];
        ffsolver = 'Sensitivity2D_Comp.edp';
    case({'axicompcomplex','axicompsponge'})
        SF_core_log('n', '## Entering SF_Sensitivity (Axi-Compressible)');
        ffparams = [ num2str(p.Results.Re), ' ',...
            num2str(p.Results.Mach), ' ', p.Results.Type, ' ', ...
            baseflow.mesh.symmetry, ' ', num2str(p.Results.k)];
        ffsolver = 'SensitivityAxi_Comp.edp';
        %ffbin = ffMPI;
     
    case ('2d')    
%         emA = eigenmodeA; em = eigenmodeD;
%         S.sensitivity = sqrt(abs(emA.ux).^2+abs(emA.uy).^2).*sqrt(abs(em.ux).^2+abs(em.uy).^2);
%         S.sensitivity = S.sensitivity/max(S.sensitivity);
%         S.mesh = emA.mesh;
%         S.datatype = 'Sensitivity';
%         S.filename = [SF_core_getopt('ffdatadir'),'MISC/Sensitivity.txt'];
%         S.datastoragemode = 'ReP2'; %% THIS METHOD DOES NOT WORK !
%         ffsolver = 'Sensitivity2D.edp';
%         sensitivity = S;
%         fid3 = fopen(S.filename,'w');
%         fprintf(fid3,'%d \n',length(S.sensitivity));
%         fprintf(fid3,' %f %f %f %f %f \n',S.sensitivity);
%         fclose(fid3);
        
        ffsolver = 'Sensitivity2D.edp';
        ffparams = '';
   
   case ({'axixr','axixrswirl'})    
        emA = eigenmodeA; em = eigenmodeD;
        if isfield(em,'uphi')
            S.sensitivity = sqrt(abs(emA.ux).^2+abs(emA.ur).^2+abs(emA.uphi).^2).*sqrt(abs(em.ux).^2+abs(em.ur).^2+abs(em.uphi).^2);
        else
            S.sensitivity = sqrt(abs(emA.ux).^2+abs(emA.ur).^2).*sqrt(abs(em.ux).^2+abs(em.ur).^2);
        end    
        S.sensitivity = S.sensitivity/max(S.sensitivity);
        S.mesh = emA.mesh;
        S.datatype = 'Sensitivity';
        S.filename = '(none)';
        ffsolver = 'none';
        sensitivity = S;     
    otherwise
        
        
        error(['Error in SF_Sensitivity : not currently implemented for problemtype = ',problemtype]);
end


if ~strcmp(ffsolver,'none')
    %% FOR CASES WHERE THE COMPUTATIONS ARE DONE BY FREEFEM SOLVER
    
% Position input files for FreeFem solver
SFcore_MoveDataFiles(baseflow.mesh.filename,'mesh.msh','cp');
SFcore_MoveDataFiles(baseflow.filename,'BaseFlow.txt','cp');
SFcore_MoveDataFiles(eigenmodeD.filename,'EigenmodeDS.txt','cp');
SFcore_MoveDataFiles(eigenmodeA.filename,'EigenmodeAS.txt','cp');

    
    
% Launching FF solver
value = SF_core_freefem(ffsolver,'parameters',ffparams);

%if (value==210) JAVIER : these tests are now done in SF_core_freefem
%    SF_core_log('e','An input file is missing!');
%    return
%elseif (value>0)
%    SF_core_log('e','Stop here');
%end



% Importing results
if (p.Results.Type == "S")
    filename = SFcore_MoveDataFiles('StructSen.ff2m','MISC');
    sensitivity = SFcore_ImportData(baseflow.mesh,filename);
end

if (p.Results.Type == "SMa")
    filename = SFcore_MoveDataFiles('SensitivityMa.ff2m','MISC');
    sensitivity = SFcore_ImportData(baseflow.mesh,filename);
end

if (p.Results.Type == "SForc")
    filename = SFcore_MoveDataFiles('SensitivityForcing.ff2m','MISC');
    sensitivity = SFcore_ImportData(baseflow.mesh,filename);
end
%     SF_core_log('n',' Estimating base flow and quasilinear mode from WNL')
%     SF_core_log('n',['### Mode characteristics : AE = ', num2str(selfconsistentmode.AEnergy), ' ; Fy = ', num2str(selfconsistentmode.Fy), ' ; omega = ', num2str(imag(selfconsistentmode.lambda))]);
%     SF_core_log('n',['### Mean-flow : Fx = ', num2str(meanflow.Fx)]);
%end
    SF_core_arborescence('cleantmpfiles') 
     
    SF_core_log('d', '### END FUNCTION SF_Sensitivity');

else %% Generic interface
     emA = SF_LoadFields(eigenmodeA); em = SF_LoadFields(eigenmodeD);
     if isfield(em,'uphi')
            S.sensitivity = sqrt(abs(emA.ux).^2+abs(emA.ur).^2+abs(emA.uphi).^2).*sqrt(abs(em.ux).^2+abs(em.ur).^2+abs(em.uphi).^2);
     elseif isfield(em,'ur') 
            S.sensitivity = sqrt(abs(emA.ux).^2+abs(emA.ur).^2).*sqrt(abs(em.ux).^2+abs(em.ur).^2);
     elseif isfield(em,'uy') 
            S.sensitivity = sqrt(abs(emA.ux).^2+abs(emA.uy).^2).*sqrt(abs(em.ux).^2+abs(em.uy).^2);
     else 
         SF_core_log('e',' Sensitivity : don''t know how to compute it in this case' )
     end    
        SF_core_log('w',' Sensitivity : here this is not normalized ; amplitude is arbitrary' )
        S.sensitivity = S.sensitivity/max(S.sensitivity);
        S.mesh = emA.mesh;
        S.datatype = 'Sensitivity';
        S.filename = '(none)';
        ffsolver = 'none';
        sensitivity = S;     

end

end