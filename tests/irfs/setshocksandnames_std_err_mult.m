%necessary because Dynare does not allow use of endo_names in strings
shocks={'e';
        'u'};
shock_size=[2 2 0;
            2 0 2];
options_.irf_opt.irf_shock_graphtitles=char('e_u','e','u');
