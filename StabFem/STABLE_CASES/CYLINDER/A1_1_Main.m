clc; clear; close all

addpath('D:\StabFem\SOURCES_MATLAB/');
SF_Start; SF_core_arborescence('cleanall');

close all;
addpath([fileparts(fileparts(pwd)), '/SOURCES_MATLAB']);
SF_Start('verbosity',2,'ffdatadir','./WORK/');
figureformat = 'tif'; 
AspectRatio = 0.75; % aspect ration for figures; nb set to 0.53 ...
                    % to regenerate exactly figures from paper
system('mkdir FIGURES');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
tic;



disp(' STARTING ADAPTMESH PROCEDURE : ');
disp(' ');
disp(' LARGE MESH : [-40:80]x[0:40] ');
disp(' ');
% bf = SF_Init('Mesh_Cylinder.edp',[-40 80 40]);
ffmesh = SF_Mesh('Mesh_Cylinder.edp','Params',[-40 80 40],'problemtype','2D');
bf = SF_BaseFlow(ffmesh,'Re',1);
bf = SF_Adapt(bf,'Hmax',2);
bf = SF_BaseFlow(bf,'Re',10);
bf = SF_BaseFlow(bf,'Re',60);
bf = SF_Adapt(bf,'Hmax',2);
meshstrategy = 'S';
% select 'D' or 'S'
% 'D' will use mesh adapted on direct eigenmode (mesh M_4):
%     this is necessary to compute correctly the structure of the mode (fig. 5a)
%     and the energy-amplitude (fig. 7d)
% 'S' will use mesh adapted on sensitivity (mesh M_2):
%     figs. (5a) and (7d) will be inacurate because lack of refinement in wake,
%     on the other hand all other results will be correct and nonlinear computations
%     will be much much faster.
if(meshstrategy=='S')
    bf=SF_BaseFlow(bf,'Re',60);
    disp('using mesh adaptated to EIGENMODE (M4) ')
    [ev,em] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','D');
    bf = SF_Adapt(bf,em,'Hmax',2);
    bf = SF_BaseFlow(bf,'Re',60);
else
    disp('mesh adaptation to SENSITIVITY : ') % This is mesh M2 from the appendix
    [ev,em] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','D');
    [ev,emA] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','A');
    emS = SF_Sensitivity(bf,em,emA);
    bf = SF_Adapt(bf,emS,'Hmax',2);
    bf = SF_BaseFlow(bf,'Re',60);
end

[ev,em]  = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','D');
[ev,emA] = SF_Stability(bf,'shift',0.04+0.76i,'nev',1,'type','A');
emS      = SF_Sensitivity(bf,em,emA);% compute on last mesh



figure(); set(gcf, 'Color', 'w'); 
SF_Plot(bf,'mesh','xlim',[-40 80],'ylim',[0 40]);
title('Initial mesh (full size)');
box on; pos = get(gcf,'Position'); 
pos(4) = pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_Mesh_Full',figureformat);

%  plot the mesh (zoom)
figure(); set(gcf, 'Color', 'w'); 
SF_Plot(bf,'mesh','xlim',[-1.5 4.5],'ylim',[0 3]);
box on; pos = get(gcf,'Position'); 
pos(4) = pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_Mesh',figureformat);




figure(); set(gcf, 'Color', 'w'); 
SF_Plot(bf,'p','xlim',[-1.5 4.5],'ylim',[0 3],'cbtitle','\omega_z',...
    'colormap','redblue','colorrange','centered','boundary','on',...
    'bdlabels',2,'bdcolors','k');
hold on;SF_Plot(bf,'psi','contour','only','clevels',[-.02 0 .2 1 2 5],...
    'xlim',[-1.5 4.5],'ylim',[0 3]);
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;
set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_BaseFlowRe60',figureformat);




%  plot the eigenmode for Re = 60
figure(); set(gcf, 'Color', 'w'); 
SF_Plot(em,'ux','xlim',[-2 8],'ylim',[0 5],'colormap',...
    'redblue','colorrange','cropcentered','boundary','on','bdlabels',2,...
    'bdcolors','k');
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;
set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_EigenModeRe60_AdaptS',figureformat);  %

figure(); set(gcf, 'Color', 'w'); 
SF_Plot(emA,'ux','xlim',[-2 8],'ylim',[0 5],'colormap',...
    'redblue','colorrange','cropcentered','boundary','on','bdlabels',...
    2,'bdcolors','k');
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;
set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_EigenModeAdjRe60',figureformat);

figure(); set(gcf, 'Color', 'w'); 
SF_Plot(emS,'S','xlim',[-2 4],'ylim',[0 3],'colormap','ice',...
    'boundary','on','bdlabels',2,'bdcolors','k');
hold on;
SF_Plot(bf,'psi','contour','only','clevels', [0 0],'xlim',[-2 4],'ylim',...
    [0 3],'colormap','ice','colorrange',[min(real(emS.S)), max(real(emS.S))]);

box on; pos = get(gcf,'Position'); 
pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_SensitivityRe60',figureformat);





plotoptions = {'ux','xlim',[-2 8],'ylim',[0 5],'colormap','redblue',...
    'colorrange','cropcentered','boundary','on','bdlabels',2,...
    'bdcolors','k'};
ev = SF_Stability(bf,'nev',20,'shift',0.74i,'PlotSpectrum',true,...
    'PlotModeOptions',plotoptions);
figure(100); set(gcf, 'Color', 'w'); 
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;
set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 14); saveas(gca,'FIGURES/SpectrumExplorator',...
    figureformat);


Re_BF = [2 : 2: 50];
Fx_BF = []; Lx_BF = [];
for Re = Re_BF
    bf = SF_BaseFlow(bf,'Re',Re);
    Fx_BF = [Fx_BF,bf.Fx];
    Lx_BF = [Lx_BF,bf.Lx];
end


% chapter 2B : figures
figure(); set(gcf, 'Color', 'w');  hold off;
LiteratureData=csvread('./literature_data/fig3a_Lw_giannetti2004.csv'); %read literature data
plot(LiteratureData(:,1),LiteratureData(:,2)+0.5,'r+-','LineWidth',2);
plot(Re_BF,Fx_BF,'b+-','LineWidth',2);
xlabel('Re');ylabel('Fx');
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_Fx_baseflow',figureformat);

figure(); set(gcf, 'Color', 'w'); hold off;
plot(Re_BF,Lx_BF,'b+-','LineWidth',2);
xlabel('Re');ylabel('Lx');
box on; pos = get(gcf,'Position'); 
pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_Lx_baseflow',figureformat);
pause(0.1);




disp('COMPUTING STABILITY BRANCH')

% LOOP OVER RE FOR BASEFLOW + EIGENMODE
Re_LIN = [40 : 2: 100];
bf = SF_BaseFlow(bf,'Re',40);
[ev,em] = SF_Stability(bf,'shift',-.03+.72i,'nev',1,'type','D');

Fx_LIN = []; Lx_LIN = [];lambda_LIN=[];
for Re = Re_LIN
    bf = SF_BaseFlow(bf,'Re',Re);
    Fx_LIN = [Fx_LIN,bf.Fx];
    Lx_LIN = [Lx_LIN,bf.Lx];
    [ev,em] = SF_Stability(bf,'nev',1,'shift','cont');
    lambda_LIN = [lambda_LIN ev];
end
completed_lambda = 1;



figure(); set(gcf, 'Color', 'w'); 
LiteratureData=csvread('./literature_data/fig4a_sigma_giannetti2004.csv'); %read literature data
plot(LiteratureData(:,1),LiteratureData(:,2),'r+-','LineWidth',2);
plot(Re_LIN,real(lambda_LIN),'b+-');
xlabel('Re');ylabel('$\sigma$','Interpreter','latex');
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_Sigma_Re',figureformat);

figure(21); set(gcf, 'Color', 'w'); hold off;
LiteratureData=csvread('./literature_data/fig4b_st_giannetti2004.csv'); %read literature data
plot(LiteratureData(:,1),LiteratureData(:,2),'r+-','LineWidth',2);
plot(Re_LIN,imag(lambda_LIN)/(2*pi),'b+-');
xlabel('Re');ylabel('St');
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
saveas(gca,'FIGURES/Cylinder_Strouhal_Re',figureformat);
pause(0.1);


disp(' ');
disp('       cpu time for Linear calculations : ');
tlin = toc;
disp([ '   ' num2str(tlin) ' seconds']);
tic;

disp(' ');
disp('######     ENTERING NONLINEAR PART       ####### ');
disp(' ');



% DETERMINATION OF THE INSTABILITY THRESHOLD
disp('COMPUTING INSTABILITY THRESHOLD');
bf = SF_BaseFlow(bf,'Re',50);
[ev,em] = SF_Stability(bf,'shift',+.75i,'nev',1,'type','D');
[bf,em] = SF_FindThreshold(bf,em); % bf,em,'solver','FindThreshold2D.edp'
Rec = bf.Re;  Fxc = bf.Fx;
Lxc = bf.Lx;    Omegac = imag(em.lambda);


[ev,em] = SF_Stability(bf,'shift',1i*Omegac,'nev',1,'type','D');
[ev,emA] = SF_Stability(bf,'shift',1i*Omegac,'nev',1,'type','A');
% Here to generate a starting point for the next chapter
[wnl,meanflow,mode] = SF_WNL(bf,em,'Adjoint',emA);


epsilon2_WNL = -0.003:.0001:.005; % will trace results for Re = 40-55 approx.
Re_WNL = 1./(1/Rec-epsilon2_WNL);
A_WNL = wnl.Aeps.*real(sqrt(epsilon2_WNL));
Fy_WNL = wnl.Fyeps.*real(sqrt(epsilon2_WNL))*2; % factor 2 because of complex conjugate
omega_WNL = Omegac + epsilon2_WNL.*imag(wnl.Lambda) ...
                  - epsilon2_WNL.*(epsilon2_WNL>0)*real(wnl.Lambda)*imag(wnl.nu0+wnl.nu2)/real(wnl.nu0+wnl.nu2)  ;
Fx_WNL = wnl.Fx0 + wnl.Fxeps2.*epsilon2_WNL  ...
                 + wnl.FxA20.*real(wnl.Lambda)/real(wnl.nu0+wnl.nu2)*epsilon2_WNL.*(epsilon2_WNL>0) ;

figure(); set(gcf, 'Color', 'w'); hold on;
plot(Re_WNL,real(wnl.Lambda)*epsilon2_WNL,'g--','LineWidth',2);hold on;

figure(21); set(gcf, 'Color', 'w'); hold on;
plot(Re_WNL,omega_WNL/(2*pi),'g--','LineWidth',2);hold on;
xlabel('Re');ylabel('St');

figure(22); set(gcf, 'Color', 'w');  hold on;
plot(Re_WNL,Fx_WNL,'g--','LineWidth',2);hold on;
xlabel('Re');ylabel('Fx');

figure(24); set(gcf, 'Color', 'w');  hold on;
plot(Re_WNL,abs(Fy_WNL),'g--','LineWidth',2);
xlabel('Re');ylabel('Fy')

figure(25); set(gcf, 'Color', 'w'); hold on;
plot(Re_WNL,A_WNL,'g--','LineWidth',2);
xlabel('Re');ylabel('AE')

pause(0.1);






disp('SC quasilinear model on the range [Rec , 100]');
Re_HB = [Rec 47 47.5 48 49 50 52.5 55 60 65 70 75 80 85 90 95 100];

% THE STARTING POINT HAS BEEN GENERATED ABOVE, WHEN PERFORMING THE WNL ANALYSIS
Res = 47.;

Lx_HB = [Lxc]; Fx_HB = [Fxc]; omega_HB = [Omegac]; Aenergy_HB  = [0]; ... 
Fy_HB = [0];

% [meanflow,mode] = SF_HB1(meanflow,mode,'solver','HB1_2D.edp','Options',{'sigma',0.,'Re',Res});
% [meanflow,mode] = SF_HB1(meanflow,mode,'Re',Res); % ,'sigma',1e-16

for Re = Re_HB(2:end)
% %     [meanflow,mode] = SF_HB1(meanflow,mode,'solver','HB1_2D.edp','Options',{'sigma',0.,'Re',Re});
%     [meanflow,mode] = SF_HB1(meanflow,mode,'sigma',1e-16,'Re',Res);
% %    Lx_HB = [Lx_HB meanflow.Lx];
%     Fx_HB = [Fx_HB meanflow.Fx];
%     omega_HB = [omega_HB imag(mode.lambda)];
%     Aenergy_HB  = [Aenergy_HB mode.AEnergy];
%     Fy_HB = [Fy_HB mode.Fy];

    if(Re==60)
       figure(); set(gcf, 'Color', 'w'); 
       SF_Plot(meanflow,'vort','xlim',[-1.5 4.5],'ylim',[0 3],'cbtitle','\omega_z','colormap','redblue','colorrange','centered','boundary','on','bdlabels',2,'bdcolors','k');
       hold on;SF_Plot(meanflow,'psi','contour','only','clevels',[-.02 0 .2 1 2 5],'xlim',[-1.5 4.5],'ylim',[0 3]);
       box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
       set(gca,'FontSize', 18);
       saveas(gca,'FIGURES/Cylinder_MeanFlowRe60',figureformat);
    end
end





% load('Cylinder_AllFigures.mat');

figure(21); set(gcf, 'Color', 'w'); hold off;
plot(Re_LIN,imag(lambda_LIN)/(2*pi),'b+-');
hold on;
plot(Re_WNL,omega_WNL/(2*pi),'g--','LineWidth',2);hold on;
plot(Re_HB,omega_HB/(2*pi),'r-','LineWidth',2);
plot(Rec,Omegac/2/pi,'ko');
LiteratureData=csvread('./literature_data/fig7a_st_Re_experience.csv'); %read literature data
plot(LiteratureData(:,1),LiteratureData(:,2),'ko','LineWidth',2);xlabel('Re');ylabel('St');
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
legend('Linear','WNL','HB1','Ref. [23]','Location','northwest');
saveas(gca,'FIGURES/Cylinder_Strouhal_Re_HB',figureformat);

figure(22); set(gcf, 'Color', 'w'); hold off;
plot(Re_LIN,Fx_LIN,'b+-');
hold on;
plot(Re_WNL,Fx_WNL,'g--','LineWidth',2);hold on;
plot(Re_HB,Fx_HB,'r+-','LineWidth',2);
plot(Rec,Fxc,'ro')
xlabel('Re');ylabel('Fx');
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio;set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
legend('BF','WNL','HB1','Location','south');
saveas(gca,'FIGURES/Cylinder_Cx_Re_HB',figureformat);


figure(24); set(gcf, 'Color', 'w'); hold off;
plot(Re_WNL,abs(Fy_WNL),'g--','LineWidth',2);
hold on;
plot(Re_HB,real(Fy_HB),'r+-','LineWidth',2);
%title('Harmonic Balance results');
xlabel('Re');  ylabel('Fy')
box on;  pos = get(gcf,'Position');  pos(4)=pos(3)*AspectRatio;  set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
legend('WNL','HB1','Location','south');
saveas(gca,'FIGURES/Cylinder_Cy_Re_SC',figureformat);

figure(25); set(gcf, 'Color', 'w'); hold off;
plot(Re_WNL,A_WNL,'g--','LineWidth',2);
hold on;
plot(Re_HB,Aenergy_HB,'r+-','LineWidth',2);
LiteratureData=csvread('./literature_data/fig7d_energy_amplitude.csv'); %read literature data
plot(LiteratureData(:,1),LiteratureData(:,2),'ko','LineWidth',2);
%title('Harmonic Balance results');
xlabel('Re');ylabel('A_E')
box on; pos = get(gcf,'Position'); pos(4)=pos(3)*AspectRatio; set(gcf,'Position',pos); % resize aspect ratio
set(gca,'FontSize', 18);
legend('WNL','HB1','Ref. [5]','Location','south');
if(meshstrategy=='D')
    filename = 'FIGURES/Cylinder_Energy_Re_SC_AdaptD';
else
    filename = 'FIGURES/Cylinder_Energy_Re_SC_AdaptS';
end
saveas(gca,filename,figureformat);


tnolin = toc;
disp(' ');
disp('       cpu time for Nonlinear calculations : ');
disp([ '   ' num2str(tnolin) ' seconds']);

disp(' ');
disp('Total cpu time for the linear & nonlinear calculations and generation of all figures : ');
disp([ '   ' num2str(tlin+tnolin) ' seconds']);


SF_Status

% [[PUBLISH]] (this tag is to enable automatic publication as html ; don't touch it !)
% [[FIGURES]] (this tag is to enable automatic generation of figures for manual or article ; don't touch it !)

%
fclose(fopen('SCRIPT_CYLINDER_ALLFIGURES.success','w+'));

%}








