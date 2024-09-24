function [EV,Rec,omegac] = SF_Stability_LoopRe(bf,Re_Range,guess_ev,varargin)

% OBSOLETE : Now use directly SF_Stability with option 'Threshold';

%
% Construction of a "branch" lambda(Re) with a loop over Re.
%
% Usage : EV =  SF_Stability_LoopRe(bf,Re_range,guess_ev, [Params, Values] )
%
%  [EV,Rec,Omegac] =  SF_Stability_LoopRe(bf,Re_range,guess_ev, [Params, Values] ) 
%
% Re_range is an array of values, typically [Restart:Restep:Reend]
% guess_ev is an approximate value of the eigenvalue at Re=Re_Range(1)
% (will be used as guess for first step, then continuation mode will be used)
%
% [Params, Values] optional parameters are the same as for SF_Stability (for instance wavenumber m, etc...) 
%
% in three-output mode Rec and Omegac are the threshold values possibly
% detected on the interval.
%
% The next parameters are couple of [Param, Values] accepted by SF_Stability
% (do not specify the shift and nev; nev will be set to 1)
%
% Example : EV = SF_Stability_LoopRe(bf,[40 : 10 : 100],'m',1,'type','D')
%
% Option 'plot' allows to plot results. Specify either true or a color (value 'yes' is used in some legacy cases).
%
% This program is part of the StabFem project distributed under gnu licence
% Copyright D. Fabre, october 9 2018
%

SF_core_log('w','OBSOLETE : don''t use any more this method') 

EV = NaN*ones(size(Re_Range));
% first step using guess
guessI = guess_ev;
Rec = [];
bf=SF_BaseFlow(bf,'Re',Re_Range(1));
%ev = SF_Stability(bf,'shift',guessI,'nev',10,varargin{:});% we take nev = 10 to make sure the first computation will be good... -> now made outside
[ev,em] = SF_Stability(bf,'shift',guessI,'nev',1,varargin{:});% to initiate the cont mode
if em.iter < 0
    SF_core_log('w',' In SF_Stability_LoopRe : Initial computation with nev=1 diverged. Trying with nev=10'); 
    ev = SF_Stability(bf,'shift',guessI,'nev',10,varargin{:});
    [ev,em] = SF_Stability(bf,'shift',ev(1),'nev',1,varargin{:});% to initiate the cont mode
    EV = ev;
else
    EV= [ev];
end

SF_core_log('n',['Starting point oif loop : Re = ',num2str(bf.Re),' : lambda = ',num2str(ev)]);
% then loop...


for i=2:length((Re_Range))
        Re = Re_Range(i);
        bfAnsIndex = bf.INDEXING;evANS=ev;
        bf = SF_BaseFlow(bf,'Re',Re);
        [ev,em] = SF_Stability(bf,'nev',1,'shift','cont',varargin{:});
        if sum(isnan(ev))
            SF_core_log('w',['Warning in SF_Stability_LoopRe : eigenvalue solver failed for Re = ',num2str(Re)]);
            EV(i:length(Re_Range)) = NaN;
            break;
        end
        SF_core_log('n',['SF_BaseFlow_LoopRe : Re = ',num2str(Re),' : lambda = ',num2str(ev)]);
        EV(i) = ev;
        if real(ev)*real(evANS)<0 
            % if a threshold is detected, write it in database
             omegac = imag((evANS*real(ev)-ev*real(evANS)))/(real(ev)-real(evANS)); 
             INDEX = punderate(bfAnsIndex, bf.INDEXING, real(ev)/(real(ev)-real(evANS)),-real(evANS)/(real(ev)-real(evANS)) ) ;
             SF_core_log('n',[' DETECTED THRESHOLD for Re = ',num2str(INDEX.Re),' : omegac = ',num2str(omegac)]);
             SF_WriteEVstats(omegac*1i,[],INDEX,'StatThreshold');
        end
        
end

% check if 'colorplot' is part of options... (to be done better)
 colorplot=false;
for i=1:nargin-3
    if(strcmpi(varargin{i},'plot'))
       colorplot = varargin{i+1}; % defined at the bottom
    end    
end
if(strcmp(colorplot,'yes')||colorplot==true)
   colorplot='r';
end


    RePLOT = Re_Range; %[Re_Range(1:Ic-1) Rec Re_Range(Ic:end)];
    EVPLOT = EV; %[EV(1:Ic-1) 1i*omegac EV(Ic:end)];

% determines a threshold if required
    Rec = [];
    Icc = find(real([EV(1) EV]).*real([EV EV(end)])<0);omegac=[];Rec=[];
    if(isempty(Icc))
        Rec = NaN;
        omegac = NaN;
    else
        for j=1:length(Icc)
            Ic = Icc(j);
            omegac = [omegac imag((EV(Ic-1)*real(EV(Ic))-EV(Ic)*real(EV(Ic-1)))/(real(EV(Ic))-real(EV(Ic-1))))]; 
            Rec = [Rec (Re_Range(Ic-1)*real(EV(Ic))-Re_Range(Ic)*real(EV(Ic-1)))/(real(EV(Ic))-real(EV(Ic-1)))];
            EVPLOT = [EVPLOT(1:Ic-1+j-1) , 1i*omegac, EVPLOT(Ic+j-1:end)]; % to draw the curves including threshold point
            RePLOT = [RePLOT(1:Ic-1+j-1) , Rec, RePLOT(Ic+j-1:end)];
        end
    end


% plot results if required...
if colorplot
figure(101);    
subplot(2,1,1);hold on;
plot(RePLOT,real(EVPLOT),[colorplot,'-'],'linewidth',2);
plot(RePLOT,0*real(EVPLOT),'k:','linewidth',1);
xlabel('Re');ylabel('\sigma'); box on;

subplot(2,1,2);hold on;
plot(RePLOT,imag(EVPLOT),[colorplot '--'],'linewidth',1);
plot(RePLOT(real(EVPLOT)>=0),imag(EVPLOT(real(EVPLOT)>=0)),[colorplot '-'],'linewidth',2);
xlabel('Re');ylabel('\omega') ; box on;   

subplot(2,1,1);hold on;
plot(Rec,0*Rec,[colorplot,'o'],'linewidth',2);
subplot(2,1,2);hold on;
plot(Rec,omegac,[colorplot,'o'],'linewidth',2);
end

pause(0.1);
end


function RES = punderate(A,B,coefA,coefB)

FIELDS = fieldnames(A);
for i=1:length(FIELDS)
    if isfield(B,FIELDS{i})
        RES.(FIELDS{i}) = coefA*A.(FIELDS{i})+coefB*B.(FIELDS{i});
    end
end
end

