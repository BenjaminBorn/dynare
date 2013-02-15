function resampled_particles = resample(particles,weights,DynareOptions)
% Resamples particles.

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

switch DynareOptions.particle.resampling.method1
  case 'residual'
    if strcmpi(DynareOptions.particle.resampling.method2,'kitagawa')
        resampled_particles = residual_resampling(particles,weights,rand);
    elseif strcmpi(DynareOptions.particle.resampling.method2,'stratified')
        resampled_particles = residual_resampling(particles,weights,rand(size(weights)));
    else
        error('particle::resample: Unknown method!')
    end
  case 'traditional'
    if strcmpi(DynareOptions.particle.resampling.method2,'kitagawa')
        resampled_particles = traditional_resampling(particles,weights,rand);
    elseif strcmpi(DynareOptions.particle.resampling.method2,'stratified')
        resampled_particles = traditional_resampling(particles,weights,rand(size(weights)));
    else
        error('particle::resample: Unknown method!')
    end
  case 'smooth'
    resampled_particles = multivariate_smooth_resampling2(particles,weights,DynareOptions.particle.resampling.number_of_partitions) ;
  otherwise
    error('particle::resample: Unknown method!')
end