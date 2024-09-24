function [] = SFcore_plotmode(~,~,filename)

%>
%> This function is called internally in "Spectrum explorator" mode
%> (launched when clicking on an eigenvalue)
%> Added by DF on january 22,2020 after IMFT seminar...
%> 

    SF_core_log('n',' ... Ploting an eigenmode in Spectrum Explorator Mode ... ' ); 
    SF_core_log('d',[ ' Using file ' , filename]);
        
    emPLOT = SFcore_ImportData(filename);
    figure;
    SF_PlotMode(emPLOT);
    
end
    

