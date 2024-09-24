%> @file SOURCES_MATLAB/SF_FindThreshold.m
%> @brief TODO ADD DESCRIPTION HERE
%>
%> @param[in] baseflow: TODO ADD DESCRIPTION HERE
%> @param[in] eigenmode: TODO ADD DESCRIPTION HERE
%> @param[out] baseflow: TODO ADD DESCRIPTION HERE
%> @param[out] eigenmode: TODO ADD DESCRIPTION HERE
%>
%> usage: <code>[baseflow, eigenmode] = SF_FindThreshold(baseflow, eigenmode)</code>
%>
%> ADD COMPLETE DOCUMENTATION HERE
%>
%> @author David Fabre
%> @date 2017-2018
%> @copyright GNU Public License
function [baseflow, eigenmode] = SF_FindThreshold(baseflow, eigenmode)

% Direct computation of instability threshold

ff = 'FreeFem++';
ffMPI = 'FreeFem++-mpi';
%ffdatadir = SF_core_getopt('ffdatadir');


%mycp(baseflow.filename, [ffdatadir, 'BaseFlow_guess.txt']);
%mycp(eigenmode.filename, [ffdatadir, 'Eigenmode_guess.txt']); 
 ffmesh = baseflow.mesh;
 SFcore_MoveDataFiles(ffmesh.filename,'mesh.msh','cp');
 SFcore_MoveDataFiles(baseflow.filename,'BaseFlow_guess.txt','cp');
 SFcore_MoveDataFiles(eigenmode.filename,'Eigenmode_guess.txt','cp');

switch(lower(baseflow.mesh.problemtype))
    case('2d')
        solverparams = [''];
       % ffbin = ff;
        ffsolver = 'FindThreshold2D.edp';
    case('axixr')
        solverparams = ['']; 
       % ffbin = ff;
        ffsolver = 'FindThresholdAxi.edp';
    case('2dcomp')
        solverparams = [num2str(baseflow.Ma) ' ', num2str(baseflow.Re)];
        ffsolver = 'FindThreshold2DComp.edp';
        %ffbin = ffMPI;
    otherwise
        error('Error in SF_FindThreshold : not (yet) available for this class of problems')
end

value = SF_core_freefem(ffsolver,'parameters',solverparams);

if (value>0)
    error('ERROR : SF_threshold flow computation did not converge');
end

SF_core_log('n',['#### Direct computation of instability threshold ']);

%baseflowT = importFFdata(baseflow.mesh, 'BaseFlow_threshold.ff2m');
%eigenmodeT = importFFdata(baseflow.mesh, 'Eigenmode_threshold.ff2m');




% The following is probably useless... moreover system(cp...) shoud be replaced by mycp
if (nargout > 0)
    %baseflow = baseflowT;
    SFcore_AddMESHFilenameToFF2M('BaseFlow_threshold.txt',baseflow.mesh.filename);
    filename = SFcore_MoveDataFiles('BaseFlow_threshold.txt','BASEFLOWS');
    baseflow = SFcore_ImportData(baseflow.mesh,filename);
    SF_core_log('n',['#### Re_c =  ', num2str(baseflow.Re)]);
    %finalname = SFcore_MoveDataFiles('BaseFlow_threshold.txt','BASEFLOWS');
%    system(['cp ', ffdatadir, 'BaseFlow_threshold.txt ', ffdatadir, 'BaseFlow.txt']);
%    system(['cp ', ffdatadir, 'BaseFlow_threshold.txt ', ffdatadir, 'BaseFlow_guess.txt']);
end
if (nargout > 1)
    %eigenmode = eigenmodeT;
    %system(['cp ', ffdatadir, 'Eigenmode_threshold.txt ', ffdatadir, 'Eigenmode_guess.txt']);
    filename = SFcore_MoveDataFiles('Eigenmode_threshold.txt','EIGENMODES');
    eigenmode = SFcore_ImportData(baseflow.mesh,filename);
    SF_core_log('n',['#### omega_c =  ', num2str(imag(eigenmode.lambda))]);
end

% eventually clean working directory from temporary files
    SF_core_arborescence('cleantmpfiles') 
     
    SF_core_log('d', '### END FUNCTION SF_FindThreshold');
end
