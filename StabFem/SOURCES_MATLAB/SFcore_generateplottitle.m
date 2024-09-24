
function [plottitle1,plottitle2] = SFcore_generateplottitle(em)
    if isfield(em,'INDEXING') && isfield(em.INDEXING,'eigenvalue')
        eigenvalue = em.INDEXING.eigenvalue;
    elseif isfield(em,'INDEXING') && isfield(em.INDEXING,'lambda')
        eigenvalue = em.INDEXING.lambda;
    else
        eigenvalue = 0;
        SF_core_log('w','Could not found a field "eigenvalue" in metadata associated to eigenmode to generate the title of the figures')
    end
    if (abs(imag(eigenvalue))/abs(real(eigenvalue)+1)<1e-6)
        eigenvalue = real(eigenvalue);
    end
    if strcmp(em.datatype,'EigenModeA')
        plottitle1 =  ['Adjoint mode,  \lambda = ',num2str(eigenvalue)];
    else
        plottitle1 =  [' \lambda = ',num2str(eigenvalue)];
    end
    plottitle2 = '';
    if isfield(em,'INDEXING')
        indexnames = fieldnames(em.INDEXING);
        for ind = indexnames'
            if ~strcmp(ind{1},'lambda')&&~strcmp(ind{1},'eigenvalue')
                if ~(strcmp(ind{1},'sym')&&em.INDEXING.(ind{1})==0)
                   plottitle2 = [plottitle2,ind{1},' = ',num2str(em.INDEXING.(ind{1})) ' ; '];
                end
            end
        end
    plottitle2 = plottitle2(1:end-3);
    end
end
