function [] = SF_RecoverDataBase(database)
%
% This function will recover a database directory 'database' in two possible ways: 
% 1/ from  the cache on the server 
%    (if previously created by a script containing the tag [[WORK]] )
% 2/ from the location /work/SF_works/(mycase)/(database).tgz 
%
if exist(database,'dir')
    disp(['Directory ',database, ' is aready present']);
elseif exist([database,'.tgz'],'file')
    disp(['A zipped version of your directory ',database, ' was found : decompacting it']);
    system(['tar xfz ',database,'.tgz']);
    
elseif ~isempty(getenv('CI')) % this checks if you are on the imft server (or you should do "export CI=1")
    [~,thecase] = fileparts(pwd); % the name of current directory
    if exist(['/work/SF_works/',thecase],'dir')
       system(['tar xfz /work/SF_works/',thecase,'/$(ls -tr /work/SF_works/',thecase,' | tail -n 1)']) 
    elseif exist(['/work/SF_data/',thecase],'dir')
       system(['tar xfz /work/SF_data/',thecase,'/$(ls -tr /work/SF_data/',thecase,' | tail -n 1)']) 
    end
    if exist(database,'dir')
        disp(['Successfully imported and unzipped directory ',database, ' from the StabFem server']);
        system(['rm ',database,'/._*']); % tar on server may introduce "._" files ???
        system(['rm ',database,'/*/._*']);
    else
        warning(['Directory ',database, 'could not be recovered from the server !']);
    end
else
    warning('could not find your directory !');
end

end



