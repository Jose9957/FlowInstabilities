
function SF_WriteEVstats(ev,EVI,BFI,filename)

%% This function is to write statistics in the STATS/ subfolder of the database
%
% Usage : res = SF_WriteEVstats(ev,EVI,BFI,filename)
%   ev : eigenvalue
%   EVI : INDEX (metadata) of the eigenvalue (CURRENTLY WILL ONLY PICK 'm' and 'k' fields if present)
%   BFI : INDEX (metadata) of the base flow
%   filename : usually will be 'StabStats" to write the datafile with eigenvalues
%   
%  OBSOLETE

%  global sfopts
  desc ='lambda_r,lambda_i';
  vals = ''; 
  
  FBFI = fieldnames(BFI);
  for i = 1:length(FBFI)
    tmp = FBFI(i); 
    thefield = tmp{1};
    desc = [desc ',' thefield];
    vals = [vals, ' ', num2str(BFI.(thefield))];
  end
  
  if isfield(EVI,'m')
    desc = [desc ',m']; 
    vals = [vals ' ' num2str(EVI.m) ];
  end
  
  if isfield(EVI,'k')
    desc = [desc ',k'];
    vals = [vals ' ' num2str(EVI.k) ];
  end
  

  SFcore_Writeff2mFile(['STATS/',filename,'.ff2m'],'datatype',filename,'datastoragemode','columns',...
  'datadescriptors',desc);

  
  fid = fopen([SF_core_getopt('ffdatadir') 'STATS/',filename,'.txt'],'a');
  for i = 1:length(ev)
    thevals = [num2str(real(ev(i))) ' ' num2str(imag(ev(i))) ' ' vals]; 
    fprintf(fid,'%s\n',thevals);
  end
  fclose(fid);
end