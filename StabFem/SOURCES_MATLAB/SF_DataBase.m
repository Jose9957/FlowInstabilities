function sfs = SF_DataBase(mode,option1,option2)
%>
%> Function SF_DataBase
%>
%>
%> @file SOURCES_MATLAB/SF_DataBase.m
%> @ Matlab function to manage the StabFem database
%>
%> Usage: 
%>  [] = SF_DataBase('create',database_dir) 
%>       creation of a database directory (clean everything if already exists)
%>
%>  [] = SF_DataBase('open',database_dir)
%>       opens an existing database directory 
%>
%> sfs = SF_DataBase('index'[,option]) 
%>       generates the index of the database. (previously SF_Status)
%>       Option is either the name of folder to generate a partial index, or 'quiet' for quiet mode
%>
%> [] = SF_Database('rm',folder,selection)
%>       To remove a selection of datasets from one folder. 
%>       Selection is is either n array of integers or keyword 'all'.
%>       Example: SF_DataBase('rm','BASEFLOWS',12:15) to remove files 12 to 15.   
%>
%> [] = SF_DataBase('clean') -> partial clean of arborescence accected by SF_core_getopt('storagemode') 
%>    'MESHES' is cleaned if SF_core_getopt('storagemode') =1
%>    'BASESFLOWS','DNSFLOWS','EIGENMODES','MISC',... are cleaned if ls storagemode = 1,2
%>    nothing is cleared if SF_core_getopt('storafemode') = 3
%> 
%> [] = SF_DataBase('cleanall') -> full clean of arborescence (including 'MESHES' ; OBSOLETE)
%>          
%> [] = SF_DataBase('cleantmpfiles') -> clean the tmp files in work dir
%>
%> [] = SF_DataBase('cleanDEBUG') -> clean the files in DEBUG folder
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
  option1=''; 
end

ffdatadir = SF_core_getopt('ffdatadir');

if(nargin<3)
  option2=[]; 
end

if (isempty(ffdatadir)||strcmp(ffdatadir,'./')||strcmp(ffdatadir,'.'))&&~strcmpi(mode,'create')&&~strcmpi(mode,'open')&&~contains(lower(mode),'disabl')  
    SF_core_log('w','SF_DataBase disabled ! use SF_DataBase(''create'',[...]) first ');
    return
end

SF_core_log('d','entering SF_DataBase');

       
%%
switch(lower(mode))
    case 'index'
        if isempty(option1)
            option1='ALL';
        end
        if isempty(option2)
            option2='verbose';
        end
        sfs = SF_Status(option1,option2);
        if (length(fields(sfs))==1)
            thefield = fields(sfs);
            sfs = sfs.(thefield{1});
        end
    case({'clean','cleanall', 'cleantmpfiles', 'cleanDEBUG'} )
        SF_core_arborescence(mode);
        sfs = [];
    case 'open'
        SF_core_setopt('ffdatadir',option1);
        sfs = [];
    case 'create'
        SF_core_setopt('ffdatadir',option1);
        SF_core_arborescence('cleanall');
        sfs = []; 
        % check if there are any '.ff2m files in the current directory'
        dd = dir;
        for i =1 :length(dd)
            if contains(dd(i).name,'.ff2m')
                SF_core_log('w','Your folder contains .txt or .ff2m files ; this is dangereous ! please clean them');
                SF_core_log('w','   (this ususally happens if you have previously launched stabfem in disabled database mode ;')
                SF_core_log('w','   please avoid using database and disable database in a same directory)'); 
            end
        end
    case 'rm'
        if ~isnumeric(option2)
            SF_core_log('e','in rm mode : thirs argument must be array of indexes')
        end
            thedir = dir([SF_core_getopt('ffdatadir'), option1,'/*.txt']); 
            thedir = nestedSortStruct(thedir, 'datenum');
            for ind = option2
                SF_core_log('w',['Removing ',thedir(ind).name]);
                [~,rootname,~] = fileparts(thedir(ind).name);
                file2 = [rootname,'.ff2m'];
                SF_core_log('w',['Removing ',file2]);
                SF_core_syscommand('rm',[ffdatadir, option1,'/',thedir(ind).name]);
                SF_core_syscommand('rm',[ffdatadir, option1,'/',file2]);
                suffixes = {'_connectivity.ff2m','_surface.ff2m','_line.ff2m','_line2.ff2m','_aux.msh','_mapping.ff2m'};
                for suf = suffixes
                   suf1 = suf{1};
                   SF_core_log('d',['removing auxiliary file ',  rootname, suf1])
                   SF_core_syscommand('rm',[ffdatadir, option1,'/', rootname, suf1]);
                end
            end
    case 'disable' 
        SF_core_log('w','Disabling database management. Some advanced functionalities may not work properly')
        SF_core_setopt('ffdatadir','./');
        
    otherwise
        SF_core_log('e','mode operation in SF_DataBase not recognized');
end            
   
% finally a legacy file still needed in old cases...
if ~exist('SF_Geom.edp','file')
 fid = fopen('SF_Geom.edp','w');
 fprintf(fid,'%s','// File automatically created by StabFem');
 fclose(fid);    
end
% a file SF_Geom should be present in some legacy cases, even if blank 
% (this line is here for retrocompatibility,  not sure it is still userul...)
    
SF_core_log('d','leaving SF_DataBase');
end
