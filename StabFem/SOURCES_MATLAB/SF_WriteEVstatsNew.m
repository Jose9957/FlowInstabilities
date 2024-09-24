
function SF_WriteEVstatsNew(Spectrum,bf,filename,Threshold,emfilenames)
%
% This function is to write statistics in the STATS/ subfolder of the database
%

desc = Spectrum.datadescriptors; 
vals = []; % to store metadata inherited from mesh and baseflow
persistent lambdaPrev MetaDataPrev;% for threshold detection

if isfield(bf,'INDEXING')
  BFI = bf.INDEXING;  
  FBFI = fieldnames(BFI);
  for i = 1:length(FBFI)
    tmp = FBFI(i); 
    thefield = tmp{1};
    desc = [desc ',' thefield];
    vals = [vals, BFI.(thefield)];
  end
end

if isfield(bf,'mesh')&&isfield(bf.mesh,'INDEXING')
  BFI = bf.mesh.INDEXING;    
  FBFI = fieldnames(BFI);
  for i = 1:length(FBFI)
    tmp = FBFI(i); 
    thefield = tmp{1};
    desc = [desc ',' thefield];
    vals = [vals, BFI.(thefield)];
  end
end


  SFcore_Writeff2mFile(['STATS/',filename,'.ff2m'],'datatype',filename,'datastoragemode','columns',...
  'datadescriptors',desc);
  
  fid = fopen([SF_core_getopt('ffdatadir') 'STATS/',filename,'.txt'],'a');  
  
  for i = 1:length(Spectrum.lambda)
    thevals = [];
    fff = fieldnames(Spectrum);
    for jj = 1:length(fff)
      thefield = fff(jj);
      thefield = thefield{1};
      if isnumeric(Spectrum.(thefield))&&~isempty(Spectrum.(thefield))
          if (imag(Spectrum.(thefield)(1))~=0)||strcmp(thefield,'lambda')||strcmp(thefield,'shift')
            thevals = [thevals, real(Spectrum.(thefield)(i)), imag(Spectrum.(thefield)(i)) ];
          else
            thevals = [thevals, Spectrum.(thefield)(i) ];
          end
      end
    end
    thevals = [thevals,vals];
    
    fprintf(fid,'%g   ',thevals);
    fprintf(fid,'\n');
    
    MetaData(i,:) = thevals;
  end
  fclose(fid);
  
 
%% Detection of threshold and generation of corresponding file

  if ~strcmpi(lower(Threshold),'off')
      
      if isempty(lambdaPrev)
        SF_core_log('w',' in SF_WriteEVStatsNew : no previous found')
        MetaDataPrev = MetaData;
        lambdaPrev   = Spectrum.lambda;
      end
      
      if ~isempty(MetaDataPrev)&&size(MetaData,2)~=size(MetaDataPrev,2)
        SF_core_log('w','no previous computation of number of metadata inconsistent : disabling Threshold detection')
      else
        
        if strcmpi(lower(Threshold),'multiple')
          maxis = min(length(Spectrum.lambda),length(lambdaPrev));
        else
          maxis = 1;
        end
        for is = 1:maxis      
          if real(lambdaPrev(is))*real(Spectrum.lambda(is))<0 
             omegac = imag((lambdaPrev(is)*real(Spectrum.lambda(is))-Spectrum.lambda(is)*real(lambdaPrev(is))))/(real(Spectrum.lambda(is))-real(lambdaPrev(is)));
             INDEX = punderate(MetaDataPrev(is,:), MetaData(is,:), real(Spectrum.lambda(is))/(real(Spectrum.lambda(is))-real(lambdaPrev(is))),-real(lambdaPrev(is))/(real(Spectrum.lambda(is))-real(lambdaPrev(is))) ) ;
             SF_core_log('n',[' DETECTED THRESHOLD for  omegac = ',num2str(omegac)]);
               SFcore_Writeff2mFile('STATS/StatThreshold.ff2m','datatype',filename,...
                                    'datastoragemode','columns','datadescriptors',desc);
             fid = fopen([SF_core_getopt('ffdatadir') 'STATS/StatThreshold.txt'],'a');  
             fprintf(fid,'%g   ',INDEX);
             fprintf(fid,'\n');
             fclose(fid);
             SFcore_MoveDataFiles(emfilenames{is},'NEARLYMARGINALMODES','cp');
          end
        end
      end
  end
  
  %% keep for next computation
  MetaDataPrev = MetaData;
  lambdaPrev   = Spectrum.lambda;
  
          
end

function RES = punderate(A,B,coefA,coefB)
  if isstruct(A)
      % not used any more but may be useful someday
     FIELDS = fieldnames(A);
    for i=1:length(FIELDS)
       if isfield(B,FIELDS{i})
           RES.(FIELDS{i}) = coefA*A.(FIELDS{i})+coefB*B.(FIELDS{i});
       end
    end
  else
    RES = coefA*A+coefB*B;
  end
end