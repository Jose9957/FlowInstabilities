function SF_TS_Stop(folder)
isdisp = 1;

    if isnumeric(folder)&&folder>0
        folder = [SF_core_getopt('ffdatadir'),'TimeStepping/RUN',sprintf('%06d',folder),'/'];
    elseif isnumeric(folder)&&folder==0
        folder = './';
    end
    SF_core_log('d',['Sending Stop signal to Time-Stepping in folder ',folder, '.....']);


%% Checking status of simulation
if  exist([folder,'/EarlyDNSend.txt'],'file')
    fid = fopen([folder,'/EarlyDNSend.txt'],'w');
    fwrite(fid,'1');
    fclose(fid);
    SF_core_log('w','Signal has been sent through file EarlyDNSend.txt ')  
    SF_core_log('w','Simulation will normally stop after current time step. Please use no SF_TS_Check to get the results.')  


elseif exist([folder,'/TS.status'],'file')
  status = fileread([folder,'/TS.status']);
  status = lower(status);
  if (status(end)==char(10)||status(end)==char(13))&&length(status)>1
    status = status(1:end-1);
  end
  if (status(end)==char(10)||status(end)==char(13))&&length(status)>1
    status = status(1:end-1);
  end
   switch status
    case 'completed'
    mymydisp(isdisp,' Simulation completed');
    case 'running'
    mymydisp(isdisp,' Simulation still running');
    case 'stopped'
    mymydisp(isdisp,' Simulation already stopped ');
     case 'diverged'
    SF_core_log('w',' Simulation diverged');
    otherwise
     SF_core_log('w',[' Status incorrectly detected ; file TS.status is  ',status]);
   end

%% Sending "stop" signal 
if strcmp(status,'running')
  SF_core_syscommand('rm',[folder,'TS.status']);
  SF_core_log('w','Signal has been sent through file TS.status ')  
  SF_core_log('w','Simulation will normally stop after current time step. Please use no SF_TS_Check to get the results.')  
else
  SF_core_log('w','no point in stopping simulation');
end

else    
  SF_core_log('w',' No file TS.status was found. It is highly advised to create one. see stabfem documentation. Assuming Runnning');
  status = 'running';
end 

end
   
function mymydisp(isdisp,string)
  if(isdisp)
    disp(string);
  end
end
 
