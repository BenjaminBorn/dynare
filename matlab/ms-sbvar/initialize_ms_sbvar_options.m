function options_=initialize_ms_sbvar_options(M_, options_)
%function initialize_ms_sbvar_options()
% sets ms sbvar options back to their default values
%
% INPUTS
%    M_:          (struct)    model structure
%    options_:    (struct)    options
%
% OUTPUTS
%    options_:    (struct)    options
%
% SPECIAL REQUIREMENTS
%    none

% Copyright (C) 2011 Dynare Team
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

% MS SBVAR
% all mex functions
options_.ms.file_tag = M_.fname;
if isfield(options_.ms,'estimation_file_tag')
    options_.ms = rmfield(options_.ms,'estimation_file_tag');
end
options_.ms.create_init = 1;
if isfield(options_.ms,'free_param_file')
    options_.ms = rmfield(options_.ms,'free_param_file');
end
if isfield(options_.ms,'simulation_file_tag')
    options_.ms = rmfield(options_.ms,'simulation_file_tag');
end
if isfield(options_.ms,'mh_file')
    options_.ms = rmfield(options_.ms,'mh_file');
end
if isfield(options_.ms,'output_file_tag')
    options_.ms = rmfield(options_.ms,'output_file_tag');
end
% prepare ms sbvar & estimation
options_.ms.coefficients_prior_hyperparameters = [1.0 1.0 0.1 1.2 1.0 1.0];
options_.ms.freq = 4;
options_.ms.initial_subperiod = 1;
options_.ms.final_subperiod=4;
options_.ms.nlags = 1;
options_.ms.cross_restrictions = 0;
options_.ms.contemp_reduced_form = 0;
options_.ms.bayesian_prior = 1;
options_.ms.alpha = 1;
options_.ms.beta = 1;
options_.ms.gsig2_lmdm = 50^2;
if isfield(options_.ms,'initial_year')
    options_.ms = rmfield(options_.ms,'initial_year');
end
if isfield(options_.ms,'final_year')
    options_.ms = rmfield(options_.ms,'final_year');
end
if isfield(options_.ms,'datafile')
    options_.ms = rmfield(options_.ms,'datafile');
end
% estimation
options_.ms.convergence_starting_value = 1e-3;
options_.ms.convergence_ending_value = 1e-6;
options_.ms.convergence_increment_value = 0.1;
options_.ms.max_iterations_starting_value = 50;
options_.ms.max_iterations_increment_value = 2;
options_.ms.max_block_iterations = 100;
options_.ms.max_repeated_optimization_runs = 10;
options_.ms.function_convergence_criterion = 0.1;
options_.ms.parameter_convergence_criterion = 0.1;
options_.ms.number_of_large_perturbations = 5;
options_.ms.number_of_small_perturbations = 5;
options_.ms.number_of_posterior_draws_after_perturbation = 1;
options_.ms.max_number_of_stages = 20;
options_.ms.random_function_convergence_criterion = 0.1;
options_.ms.random_parameter_convergence_criterion = 0.1;
% simulation
options_.ms.mh_replic = 10000; % default differs from Dan's code
options_.ms.thinning_factor = 1;
options_.ms.drop = 0.1*options_.ms.mh_replic*options_.ms.thinning_factor;
options_.ms.adaptive_mh_draws = 30000;
% mdd
options_.ms.mdd_proposal_draws = 100000;
options_.ms.mdd_use_mean_center = 0;
options_.ms.mdd_proposal_type = [3 0.1 0.9];
% probabilities
options_.ms.filtered_probabilities = 0;
options_.ms.real_time_smoothed_probabilities = 0;
% irf
options_.ms.horizon = 12;
options_.ms.filtered_probabilities = 0;
options_.ms.error_bands = 1;
options_.ms.error_band_percentiles = [.16 .5 .84];
options_.ms.parameter_uncertainty = 0;
options_.ms.shock_draws = 10000;
options_.ms.shocks_per_parameter = 10;
options_.ms.median = 0;
% forecast
options_.ms.forecast_data_obs = 0;
end
