%> THIS ONE SHOULD NOT BE USED ANY MORE !

%> @file SOURCES_MATLAB/SFcore_CleanDir.m
%> @brief Matlab function to clean a directory in the StabFem arborescence
%>
%> Usage: [] = SFcore_CleanDir(dirname)
%> 
%> remarks : 
%> 1. can work with several directory names ! for instance :
%>      [] : SFcore_CleanDir('BASEFLOWS','MESHES')
%> 2. special modes : 
%>      SFcore_CleanDir('MESH_FORCE')     
%>          -> if you really want to clean theMESH directory (usually not advised)
%>      SFcore_CleanDir('TMPFILES')
%>          -> to clean the directory from *.txt, *.msh, *.ff2m files
%>             (except problemtype.ff2m which must stay there)
%>      SFcore_CleanDir('POSTADAPT')
%>           -> All directories apart from MESHES
%> dirname is expected to be a subdirectory of ffdatadir

function SFcore_CleanDir(varargin)

SF_core_log('l','SFcore_CleanDir SHOULD NOT BE USED ANY MORE ! please use SF_core_arborescence instead' );  


if (length(varargin)==1) && strcmp(varargin(1),'POSTADAPT')
    varargin = {'BASEFLOWS','MEANFLOWS','DNSFIELDS','EIGENMODES','MISC','FORCEDFLOWS','DNSSTATS','FORCEDSTATS'};
end

ffdatadir = SF_core_getopt('ffdatadir');

if ~strcmp(ffdatadir,'.')&&~strcmp(ffdatadir,'./')

for dirname = varargin
    if  isempty(strfind(dirname{:},'MESHES'))&&isempty(strfind(dirname{:},'TMPFILES'))
        fulldirname = [ffdatadir filesep dirname{:}];
        SF_core_syscommand('rm',fulldirname);
        SF_core_syscommand('mkdir',fulldirname);        
        SF_core_log('nnn',['Cleaning directory ',fulldirname]);
    elseif strcmp(dirname{:},'MESHES_FORCE') 
          fulldirname = [ffdatadir '/' 'MESHES'];
          SF_core_syscommand('rm',fulldirname);
          SF_core_syscommand('mkdir',fulldirname);
          SF_core_log('nnn',['Cleaning directory ',fulldirname]);
    elseif strcmp(dirname{:},'TMPFILES') 
%          system(['rm ' ffdatadir '*']) except problemtype;
          thedir = dir(ffdatadir);
          for i = 1:length(thedir)
            if (~thedir(i).isdir)&&(~strcmp(thedir(i).name,'problemtype.ff2m'))
              SF_core_syscommand('rm',[ffdatadir thedir(i).name]);
            end
          end
          SF_core_log('nnn',['Cleaning directory ',ffdatadir]);
    elseif strcmp(dirname{:},'MESHES')
         SF_core_log('e','Cleaning directory MESH is not advised apart when restarting everything... use ''MESHES_FORCE'' if you really insist');
    else
        SF_core_log('e','unrecognized parameter' );       
    end
end
end
end
