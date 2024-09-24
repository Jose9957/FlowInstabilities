

% script d'essai de catching de differents types d'erreurs.

% COMPORTEMENT ATTENDU : 
% 1/ en mode 'verbosity = 0'  le script doit continuer mais détailler les
% erreurs (ou mieux les écrire dans un fichier log)

% en mode 'verbosity>0' le programme doit génerer une erreur (ou un warning) explicite

% Tester tous les cas suivants en mode verbosity = 4 et verbosity = 0


addpath('../../SOURCES_MATLAB/');
SF_core_start('verbosity',4,'workdir','./WORK/') % NB these two parameters are optional ; SF_core_Start() will do the same
sfstat = SF_Status();
if strcmp(sfstat.status,'new')
    bf = SmartMesh_Cylinder;    
else
    bf = SF_Load('lastadapted'); % pour recuperer le dernier champ de base
end
%% Premiere serie : erreurs FreeFem++

%% test erreur 1 : Freefem code does not exist (testing through SF_Mesh driver)
disp('test 1');
dumb = SF_Mesh('toto.edp');

%% test erreur 2 : Syntax error in the .edp file
disp('test 2');
system('echo tugudugudu > Test1.edp')
dumb = SF_Mesh('Test1.edp');

%% test erreur 3 : trying to load an invalid file
disp('test 3');
bfWRONG = bf;
bfWRONG.filename =  './WORK/MESHES/BaseFlow_adapt2_Re60.txt'; % this file exit but is incompatible
SF_BaseFlow(bfWRONG,'Re',61);


%% test erreur 4 : divergence du Newton (dans ce cas le programme principal ne doit pas s'arrêter)
disp('test 3');
bf = SF_BaseFlow(bf,'Re',-1000);

%% test erreur 5 : divergence dans le Shift-invert (dans ce cas le programme principal ne doit pas s'arrêter)
disp('test 4');
[ev,em] = SF_Stability(bf,'shift',4i,'nev',1);

%% test erreur 6 a prevoir : mesh adaptation failed 
% (en general c'est parce que le recalcul du champ de base post adapt a
% divergé, erreur assez courante mais un peu délicate à gerer...)
%bf = SF_Adapt(bf)

%% Seconde serie : erreurs manipulations de fichiers StabFem


%% test erreur 21 : fichier n'existe pas
disp('test 21');

bfWRONG = bf;
bfWRONG.filename = 'nofile.txt';
bf = SF_BaseFlow(bfWRONG,'Re',100);



