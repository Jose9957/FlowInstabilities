function [bf,EV,Rec,omegac,KOut,status] = SF_Stability_LoopBisRe(bf,Re_Range,k_Range,guess_ev,varargin)
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
% in three-output mode Rec and Omegac are the threshold values possibly
% detected on the interval.
%
% The next parameters are couple of [Param, Values] accepted by SF_Stability
% (do not specify the shift and nev; nev will be set to 1)
%
% Example : EV = SF_Stability_LoopRe(bf,[40 : 10 : 100],'m',1,'type','D')
%
% Option 'plot' allows to plot results. Specify  either 'yes' or a color.
%
% This program is part of the StabFem project distributed under gnu licence
% Copyright D. Fabre, october 9 2018
%

p = inputParser;
addParameter(p, 'k', 0, @isnumeric);
if (isfield(bf, 'Ma')) MaDefault = bf.Ma;
else MaDefault = 0.01;
end;
addParameter(p, 'Mach', MaDefault, @isnumeric); % Mach
if (isfield(bf, 'Omegax')) OmegaxDefault = bf.Omegax;
else OmegaxDefault = 0;
end
addParameter(p, 'Omegax', OmegaxDefault, @isnumeric); % rotation rate (for swirling body)
parse(p, varargin{:});

Ma = p.Results.Mach;
Omegax = p.Results.Omegax;
EV = NaN*ones(size(Re_Range));
% first step using guess
guessI = guess_ev;
K(1) = k_Range(1);
bf=SF_BaseFlow(bf,'Re',Re_Range(1),'Mach',Ma,'Omegax',Omegax,'type','NEW');
[ev,em] = SF_Stability(bf,'k',K(1),'shift',guessI,'nev',10);% we take nev = 10 to make sure the first computation will be good... -> now made outside
[ev,em] = SF_Stability(bf,'k',K(1),'shift',ev(1),'nev',1);% to initiate the cont mode
EV(1)= ev;
% then loop...


for i=2:length((Re_Range))
        Re = Re_Range(i);
        bf = SF_BaseFlow(bf,'Re',Re,'Mach',Ma,'Omegax',Omegax);
        for j=1:length((k_Range))
            kVal = k_Range(j);
            evkPrev = ev;
            [ev,em] = SF_Stability(bf,'k',kVal,'nev',1,'shift','cont');
            if(real(ev)<real(evkPrev) && j>1) % Under the hypothesis the function is coercive with a single maximum (relative)
                break;
            end
            EV(i) = ev;
           	KOut = kVal;
        end
        if(real(ev)*real(evkPrev)<0) % Th Bolzano. Stop bisection in Re.
           break;
        end
        if(em.iter==-1)
            mydisp(2,['Warning in SF_Stability_LoopRe : eigenvalue solver failed for Re = ',num2str(Re)]);
            break;
        end
        disp(['Re = ',num2str(Re),' : lambda = ',num2str(ev)]);
end


    RePLOT = Re_Range; %[Re_Range(1:Ic-1) Rec Re_Range(Ic:end)];
    EVPLOT = EV; %[EV(1:Ic-1) 1i*omegac EV(Ic:end)];

% determines a threshold if required
    Rec = [];
    Icc = find(real([EV(1) EV]).*real([EV EV(end)])<0);omegac=[];Rec=[];
    if(isempty(Icc))
        Rec = interp1(real(EV),Re_Range,0,'spline','extrap');
        omegac = interp1(real(EV),imag(EV),0,'spline','extrap');
        status = 0;
    else
        for j=1:length(Icc)
            Ic = Icc(j);
            omegac = [omegac imag((EV(Ic-1)*real(EV(Ic))-EV(Ic)*real(EV(Ic-1)))/(real(EV(Ic))-real(EV(Ic-1))))]; 
            Rec = [Rec (Re_Range(Ic-1)*real(EV(Ic))-Re_Range(Ic)*real(EV(Ic-1)))/(real(EV(Ic))-real(EV(Ic-1)))];
            EVPLOT = [EVPLOT(1:Ic-1+j-1) , 1i*omegac, EVPLOT(Ic+j-1:end)]; % to draw the curves including threshold point
            RePLOT = [RePLOT(1:Ic-1+j-1) , Rec, RePLOT(Ic+j-1:end)];
            status = 1;
        end
    end

end


    
