%%  POST-PROCESSING for linear Stability analysis of the wake of a cylinder
%
% this scripts demonstrates how to use the data-mining features of the
% StabFem software for post-processing after generation of a large number of data.
%
% It is designed to be used as a tutorial. For this, you should have
% previously run the script <https://stabfem.gitlab.io/StabFem/stable/cylinder/CYLINDER_LINEAR.html CYLINDER_LINEAR.m>, 
% which has generated a number of data (baseflows, eigenmodes, eigenvalues) and stored them in a
% directory './WORK/'.
% 





%%
% First we restart StabFem specifying as 'workdir ' the directory '/WORK/'
% which has been used in the previous script.

if SF_core_getopt('SF_PUBLISH')
    CYLINDER_LINEAR; % trick for correct execution by the the gitlab runner generating the html page
end

close all;
addpath([fileparts(fileparts(pwd)), '/SOURCES_MATLAB']);
SF_Start('verbosity',3,'ffdatadir','./WORK/');

%%
% Then we use the <https://gitlab.com/stabfem/StabFem/blob/master/SOURCES_MATLAB/SF_Status.m SF_Status.m> 
% data-mining wizard to generate a structure allowing to
% access the whole content of this directory :

sf = SF_Status('ALL')

%%
% We can see that we have previously created 5 meshes (during the mesh-adaptation process), 
% stored 18 baseflows computed with the current mesh, and 6 eigenmodes. 

%%
% Let us first have a look at the contents of the 'BASEFLOWS' object:

sf.BASEFLOWS

%%
% You can see that there are 18 baseflows indexed with Re and Fx.
% You may wonder how StabFem knows how to do the indexing ? This is thanks
% to "metatada" written in the .ff2m files. This is controlled by the macro
% SFwriteBaseFlow.  In the present case this macro is in the file
% <https://gitlab.com/stabfem/StabFem/blob/master/STABLE_CASES/CYLINDER/SF_Custom.idp SF_Custom.idp> 
% in the working directory. Have a look in this file to understand how it works !

%%
% If we want to import any of the available datafiles (baseflows or eigenmodes), 
% we can use the function <https://gitlab.com/stabfem/StabFem/blob/master/STABLE_CASES/CYLINDER/SF_Load.m SF_Load.m>. 
% For instance here is how to import the latest baseflow and plot it:

bf = SF_Load('BASEFLOWS','last') 

figure(15);
SF_Plot(bf,'vort','xlim',[-1.5 4.5],'ylim',[0 3],'cbtitle','\omega_z','colormap','redblue','colorrange',[-2 2]);
hold on;SF_Plot(bf,'psi','contour','only','clevels',[-.02 0 .2 1 2 5],'xlim',[-1.5 4.5],'ylim',[0 3]);
box on;  set(gca,'FontSize', 18);hold off;

%% 
% SF_Status also returns a structure 'EIGENVALUES' containing all the computed 
% eigenvalues. Let us see what is available here:

sf.EIGENVALUES

%% 
% We can see that there have been 11 eigenvalue computations, and that
% metadata 'Re', 'Fx', 'm' and 'k' have been generated. Here 'Re' is the Reynolds 
% number ; 'k' is the transverse wavenumber and 'm' is the symmetry condition 
% (-1 for antisymmetric modes and +1 for symmetric modes).
% (here only antisymmetric 2D modes have been computed, hence m=-1 and k=0 for all)

%%
% The structure 'EIGENMODES' contains info only on the Eigenmodes for which
% a datafile has been stored (they have been processed as [ev,em] = SF_Stability(...)
% instead of ev = SF_Stability(...) ). Let us see what is in this structure :

sf.EIGENMODES

%%
% If we now wish to re-generate the plot of the real and imaginary part of
% the eigenvalue of the leading eigenmode, simply do this :

figureformat='png'; 

figure(20);subplot(2,1,1);
plot(sf.EIGENVALUES.Re,real(sf.EIGENVALUES.lambda),'b+');
xlabel('Re');ylabel('$\sigma$','Interpreter','latex');
box on; set(gca,'FontSize', 18); saveas(gca,'FIGURES/Cylinder_Sigma_Re',figureformat);

figure(20);subplot(2,1,2);
plot(sf.EIGENVALUES.Re,imag(sf.EIGENVALUES.lambda)/(2*pi),'b+');
xlabel('Re');ylabel('St');
box on; set(gca,'FontSize', 18); saveas(gca,'FIGURES/Cylinder_Strouhal_Re',figureformat);
pause(0.1);

% [[PUBLISH]] (this tag is to enable automatic publication as html ; don't touch it !)
