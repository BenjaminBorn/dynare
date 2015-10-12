function [xcum] = priorcdf(para, pshape, p6, p7, p3, p4)
% This procedure transforms x vectors into cumulative values 
% pshape: 0 is point mass, both para and p2 are ignored
%         1 is BETA(mean,stdd)
%         2 is GAMMA(mean,stdd)
%         3 is NORMAL(mean,stdd)
%         4 is INVGAMMA(s^2,nu)
%         5 is UNIFORM [p1,p2]
%         6 is INVGAMMA [p1,p2]
%         7 is DIRICHLET 
%         8 is WEIBULL [p1,p2,p3]
% 
% Adapted by M. Ratto from MJ priordens.m

% Copyright (C) 2012-14 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

nprio 	= length(pshape);

i = 1;
while i <=  nprio;
	a = 0;	
	b = 0;
	if pshape(i) == 1;     % (generalized) BETA Prior 
% 		mu = (p1(i)-p3(i))/(p4(i)-p3(i));
% 		stdd = p2(i)/(p4(i)-p3(i));
% 		a = (1-mu)*mu^2/stdd^2 - mu;
% 		b = a*(1/mu - 1);
		%lnprior = lnprior + lpdfgbeta(para(i),a,b,p3(i),p4(i))   ;
		para(:,i) = (para(:,i)-p3(i))./(p4(i)-p3(i));
% 		xcum(:,i) = betacdf(para(:,i),a,b)   ;
    xcum(:,i) = betainc(para(:,i),p6(i),p7(i));
  elseif pshape(i) == 2; % GAMMA PRIOR 
%      	b = p2(i)^2/(p1(i)-p3(i));
% 		a = (p1(i)-p3(i))/b;
		%lnprior = lnprior + lpdfgam(para(i)-p3(i),a,b);
% 		xcum(:,i) = gamcdf(para(:,i)-p3(i),a,b);
    xcum(:,i) = gamcdf(para(:,i)-p3(i),p6(i),p7(i));
	elseif pshape(i) == 3; % GAUSSIAN PRIOR 
     %lnprior = lnprior + lpdfnorm(para(i),p1(i),p2(i));
%      xcum(:,i) = normcdf(para(:,i),p1(i),p2(i));
     xcum(:,i) = 0.5 * erfc(-(para(:,i)-p6(i))/p7(i) ./ sqrt(2));
	elseif pshape(i) == 4; % INVGAMMA1 PRIOR 
     	%lnprior = lnprior + lpdfig1(para(i),p1(i),p2(i));
%   		xcum(:,i) = gamcdf(1/para(:,i).^2,p2(i)/2,2/p1(i));
      xcum(:,i) = gamcdf(1./(para(:,i)-p3(i)).^2,p7(i)/2,2/p6(i));
	elseif pshape(i) == 5; % UNIFORM PRIOR 
     	%lnprior = lnprior + log(1/(p2(i)-p1(i)));
  		xcum(:,i) = (para(:,i)-p3(i))./(p4(i)-p3(i));
 	elseif pshape(i) == 6; % INVGAMMA2 PRIOR 
%     	lnprior = lnprior + lpdfig2(para(i),p1(i),p2(i));
%   		xcum(:,i) = gamcdf(1/para(:,i),p2(i)/2,2/p1(i));
      xcum(:,i) = gamcdf(1./(para(:,i)-p3(i)),p7(i)/2,2/p6(i));
 	elseif pshape(i) == 7; % Dirichlet PRIOR 

    elseif pshape(i) == 8; % WEIBULL PRIOR 
      xcum(:,i) = wblcdf(para(:,i)-p3(i),p6(i),p7(i));
	end;
	i = i+1;
end;

