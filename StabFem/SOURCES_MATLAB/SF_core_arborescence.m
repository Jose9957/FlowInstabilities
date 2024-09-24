function [] = SF_core_arborescence(mode,ffdatadir)
%
% Function SF_core_arborescence
% (partly redundant with SFcore_CleanDir)
%
%>
%> @file SOURCES_MATLAB/SF_core_arborescence.m
%> @brief Matlab function to create or clean clean the StabFem arborescence
%>
%> Usage: 
%> [] = SF_core_arborescence('create') -> creation of arborescence
%>          
%> [] = SF_core_arborescence('clean') -> partial clean of arborescence accected by SF_core_getopt('storagemode') 
%>    'MESHES' is cleaned if SF_core_getopt('storagemode') =1
%>    'BASESFLOWS','DNSFLOWS','EIGENMODES','MISC',... are cleaned if ls storagemode = 1,2
%>    nothing is cleared if SF_core_getopt('storafemode') = 3
%> 
%> [] = SF_core_arborescence('cleanall') -> full clean of arborescence (including 'MESHES' ; OBSOLETE)
%>          
%> [] = SF_core_arborescence('cleantmpfiles') -> clean the tmp files in work dir
%> 
%> remarks : 
%> 1/ Function disabled when working in the base dir (ffdatadir = './') or debug mode (verbosity>5) 
%>
%> 2/ (TO BE CHECKED) operation is affected by the global variable SF_core_getopt('storagemode') as follows :
%>          0 : no storage of data files (everything is kept in base directory workdir, nothing is put in subfolders)
%>          1 : stores results but cleans everything each time the
%>              mesh is reconstructed (recommended for static free-surface problems)
%>          2 : stores everything, each time the mesh is
%>              reconstructed we clean everything but keep a copy of each new mesh in subdirectory MESHES 
%>              (default mode, recommended for cases where the mesh is only adapted at the start) 
%>          3 : stores and keeps everything (SF_BaseFlow is automatically in 'force' mode)     


if(nargin<2)
  ffdatadir = SF_core_getopt('ffdatadir'); % to be continued
end

if isempty(ffdatadir)||strcmp(ffdatadir,'./')||strcmp(ffdatadir,'.') 
    SF_core_log('nnn','SF_core_arborescence disabled when using  "./" as workdir ');
    return
end

%if (SF_core_getopt('verbosity')>5)&&~strcmp(mode,'create')
%    SF_core_log('d','SF_core_arborescence disabled in debug mode ');
%    return
%end

SF_core_log('d','entering SF_core_arborescence');

if(nargin==0)
    mode = 'create';
end


% list of directories to create
SFDirList0 = {'BASEFLOWS','EIGENMODES','MISC',...
            'MEANFLOWS','FORCEDFLOWS','DNSFIELDS','STATS', 'FORCEDSTATS','DEBUG'};
         
% list of directories to clean
dd = dir(SF_core_getopt('ffdatadir'));
ddname = {dd.name};
dddir = [dd.isdir];
SFDirList = ddname(dddir);
         
%%
switch(mode)
    case('create')
        SF_core_log('d','CREATE in SF_core_arborescence');
       % SF_core_syscommand('rmdir',ffdatadir); % NOOOO !
        SF_core_syscommand('mkdir',ffdatadir);
        SF_core_syscommand('mkdir',[ffdatadir 'MESHES']);
        for i = 1:length(SFDirList0)
            %[ffdatadir SFDirList{i} ]
            SF_core_syscommand('mkdir',[ffdatadir SFDirList0{i} ]);
        end
        
        if ~exist('SF_Geom.edp','file')
          fid = fopen('SF_Geom.edp','w');
          fprintf(fid,'%s','// File automatically created by StabFem');
          fclose(fid);
        end
   
    case ('clean')
       if(SF_core_getopt('storagemode')==1||SF_core_getopt('storagemode')==2)    
       SF_core_log('d','CLEAN DATA DIRECTORIES in SF_core_arborescence');
       for i = 1:length(SFDirList)
            if isempty(strfind(SFDirList{i},'.'))
              SF_core_syscommand('cleandir',[ffdatadir SFDirList{i} ]);
              SF_core_syscommand('mkdir',[ffdatadir SFDirList{i} ]);
            end
       end 
       if(SF_core_getopt('storagemode')==1)    
       SF_core_log('d','CLEAN also MESH DIRECTORIES in SF_core_arborescence');
            SF_core_syscommand('cleandir',[ffdatadir 'MESHES' ]);
            SF_core_syscommand('mkdir',[ffdatadir 'MESHES' ]);
       end
       else
          SF_core_log('d','cLean dir DISABLED in SF_core_arborescence') 
       end
       
      case('cleanall')
        if(SF_core_getopt('storagemode')==1||SF_core_getopt('storagemode')==2)  
            %SF_core_log('l','CLEANALL in SF_core_arborescence (legacy; better use clean and SF_core_getopt('storagemode') to control)');
          SF_core_log('n',['CLEANALL in SF_core_arborescence ; working dir ',SF_core_getopt('ffdatadir'),' is now empty']); 
          SFDirListALL = ['MESHES' 'STATS' SFDirList];
          for i = 1:length(SFDirListALL)
            if isempty(strfind(SFDirListALL{i},'.'))
              SF_core_syscommand('cleandir',[ffdatadir SFDirListALL{i} ]);
              SF_core_syscommand('mkdir',[ffdatadir SFDirListALL{i} ]);
            end
          end
          SF_core_log('n',['Cleaning ALL arborescence ',SF_core_getopt('ffdatadir')]); 
        else
          SF_core_log('n','cLean dir DISABLED in SF_core_arborescence with storagemode = 3') 
        end
          
    case 'cleantmpfiles'
        
        SF_core_log('d','CLEANTMPFILES in SF_core_arborescence');
        if SF_core_getopt('verbosity')<5 
           % SFcore_CleanDir('TMPFILES');
            thedir = dir(SF_core_getopt('ffdatadir'));
            for i = 1:length(thedir)
                %[SF_core_getopt('ffdatadir') thedir(i).name]
                if (~thedir(i).isdir)&&(~strcmp(thedir(i).name,'problemtype.ff2m'))
                    %[SF_core_getopt('ffdatadir') thedir(i).name]
                    SF_core_syscommand('rm',[SF_core_getopt('ffdatadir') thedir(i).name]);
                end
            end
             SF_core_log('nnn',['Cleaning directory ',SF_core_getopt('ffdatadir')]);
        else
            SF_core_log('d',' NB cleaning of temporary files is disabled in debug mode');
        end
      
    case 'cleanDEBUG'  
         % cleaningg folder DEBUG as well
            thedir = dir([SF_core_getopt('ffdatadir'),'/DEBUG*/']);
            for i = 1:length(thedir)
                if (~thedir(i).isdir)
                  SF_core_syscommand('rm',[SF_core_getopt('ffdatadir'),'/DEBUG/', thedir(i).name]);
                end
            end
            SF_core_log('nnn',['Cleaning directory ',SF_core_getopt('ffdatadir'), '/DEBUG as well']);
        
    case default
        SF_core_log('e','mode operation in SF_core_arborescence not recognized');
end            
   
% finaly a legacy file still needed in old cases...
if ~exist('SF_Geom.edp','file')
 fid = fopen('SF_Geom.edp','w');
 fprintf(fid,'%s','// File automatically created by StabFem');
 fclose(fid);    
end
% a file SF_Geom should be present in some legacy cases, even if blank 
% (this line is here for retrocompatibility,  not sure it is still userul...)
    
SF_core_log('d','leaving SF_core_arborescence');
end
