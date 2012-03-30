function new_etat = multivariate_smooth_resmp(weights,particles,number,number_of_partitions)
% Smooth Resamples particles.

%@info:
%! @deftypefn {Function File} {@var{indx} =} resample (@var{weights}, @var{method})
%! @anchor{particle/resample}
%! @sp 1
%! Resamples particles.
%! @sp 2
%! @strong{Inputs}
%! @sp 1
%! @table @ @var
%! @item weights
%! n*1 vector of doubles, particles' weights.
%! @item method
%! string equal to 'residual' or 'traditional'.
%! @end table
%! @sp 2
%! @strong{Outputs}
%! @sp 1
%! @table @ @var
%! @item indx
%! n*1 vector of intergers, indices.
%! @end table
%! @sp 2
%! @strong{This function is called by:}
%! @sp 1
%! @ref{particle/sequantial_importance_particle_filter}
%! @sp 2
%! @strong{This function calls:}
%! @sp 1
%! @ref{residual_resampling}, @ref{traditional_resampling}
%! @sp 2
%! @end deftypefn
%@eod:

% Copyright (C) 2011, 2012 Dynare Team
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

% AUTHOR(S) frederic DOT karame AT univ DASH evry DOT fr
%           stephane DOT adjemian AT univ DASH lemans DOT fr

number_of_particles = length(weights);
number_of_states = size(particles,2); 
number = number_of_particles/number_of_partitions ; 
tout = sort([particles weights],1) ;
particles = tout(:,1:number_of_states) ;
weights = tout(:,1+number_of_states) ;
cum_weights = cumsum(weights) ;    
new_etat = zeros(number_of_particles,number_of_states) ;
indx = 1:number_of_particles ; 
for i=1:number_of_partitions
    if i==number_of_partitions 
      tmp = bsxfun(@ge,cum_weights,(i-1)/number_of_partitions) ;
      kp = indx( tmp ) ;
    else 
      tmp = bsxfun(@and,bsxfun(@ge,cum_weights,(i-1)/number_of_partitions),bsxfun(@lt,cum_weights,i/number_of_partitions)) ;
      kp = indx( tmp ) ;
    end
    if numel(kp)>2    
        Np = length(kp) ;
        wtilde = [ ( number_of_partitions*( cum_weights(kp(1)) - (i-1)/number_of_partitions) ) ; 
                   ( number_of_partitions*weights(kp(2:Np-1)) ) ; 
                   ( number_of_partitions*(i/number_of_partitions - cum_weights(kp(Np)-1) ) ) ] ;
        test = sum(wtilde) ;
        new_etat_j = zeros(number,number_of_states) ;
        for j=1:number_of_states
          etat_j = particles(kp,j) ; 
          if j>1 
            tout = sort( [ etat_j wtilde],1) ;
            etat_j = tout(:,1) ;
            wtilde = tout(:,2) ; 
          end 
          new_etat_j(:,j) = univariate_smooth_resmp(wtilde,etat_j,number) ;
        end
        new_etat((i-1)*number+1:i*number,:) = new_etat_j ;
    end    
end
