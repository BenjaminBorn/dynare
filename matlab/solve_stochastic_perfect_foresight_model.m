function [flag,endo_simul,err] = solve_stochastic_perfect_foresight_model(endo_simul,exo_simul,pfm,nnodes,order)

    flag = 0;
    err = 0;
    stop = 0;

    params = pfm.params;
    steady_state = pfm.steady_state;
    ny = pfm.ny;
    periods = pfm.periods;
    dynamic_model = pfm.dynamic_model;
    lead_lag_incidence = pfm.lead_lag_incidence;
    nyp = pfm.nyp;
    nyf = pfm.nyf;
    i_cols_1 = pfm.i_cols_1;
    i_cols_A1 = pfm.i_cols_A1;
    i_cols_j = pfm.i_cols_j;
    i_cols_T = nonzeros(lead_lag_incidence(1:2,:)');
    
    maxit = pfm.maxit_;
    tolerance = pfm.tolerance;
    verbose = pfm.verbose;
    
    number_of_shocks = size(exo_simul,2);

    [nodes,weights] = gauss_hermite_weights_and_nodes(nnodes);
    
    if number_of_shocks>1
        nodes = repmat(nodes,1,number_of_shocks)*chol(pfm.Sigma_e);
        % to be fixed for Sigma ~= I
        for i=1:number_of_shocks
            rr(i) = {nodes(:,i)};
            ww(i) = {weights};
        end
        nodes = cartesian_product_of_sets(rr{:});
        weights = prod(cartesian_product_of_sets(ww{:}),2);
        nnodes = nnodes^number_of_shocks;
    else
        nodes = nodes*sqrt(pfm.Sigma_e);
    end

    innovations = zeros(periods+2,number_of_shocks);

    if verbose
        disp ([' -----------------------------------------------------']);
        disp (['MODEL SIMULATION :']);
        fprintf('\n');
    end

    z = endo_simul(find(lead_lag_incidence'));
    [d1,jacobian] = dynamic_model(z,exo_simul,params,steady_state,2);

    % Each column of Y represents a different world
    % The upper right cells are unused
    % The first row block is ny x 1
    % The second row block is ny x nnodes
    % The third row block is ny x nnodes^2
    % and so on until size ny x nnodes^order
    world_nbr = nnodes^order;
    Y = repmat(endo_simul(:),1,world_nbr);
    
    % The columns of A map the elements of Y such that
    % each block of Y with ny rows are unfolded column wise
    dimension = ny*(sum(nnodes.^(0:order-1),2)+(periods-order)*world_nbr);
    if order == 0
        i_upd = ny+(1:ny*periods);
    else
        i_upd = zeros(dimension,1);
        i_upd(1:ny) = ny+(1:ny);
        i1 = ny+1;
        i2 = 2*ny;
        n1 = 2*ny+1;
        n2 = 3*ny;
        for i=2:periods
            k = n1:n2;
            for j=1:nnodes^min(i-1,order)
                i_upd(i1:i2) = (n1:n2)+(j-1)*ny*(periods+2);
                i1 = i2+1;
                i2 = i2+ny;
            end
            n1 = n2+1;
            n2 = n2+ny;
        end
    end
    
    h1 = clock;
    for iter = 1:maxit
        h2 = clock;
        A = sparse([],[],[],dimension,dimension,(periods+2)*world_nbr*nnz(jacobian));
        res = zeros(dimension,1);
        i_rows = 1:ny;
        i_cols = find(lead_lag_incidence');
        i_cols_p = i_cols(1:nyp);
        i_cols_s = i_cols(nyp+(1:ny));
        i_cols_f = i_cols(nyp+ny+(1:nyf));
        i_cols_A = i_cols;
        i_cols_Ap = i_cols_p;
        i_cols_As = i_cols_s;
        i_cols_Af = i_cols_f - ny;
        for i = 1:periods
            if i <= order+1
                i_w_p = 1;
                for j = 1:nnodes^(i-1)
                    innovation = exo_simul;
                    if i > 1
                        innovation(i+1,:) = nodes(mod(j-1,nnodes)+1,:);
                    end
                    if i <= order
                        for k=1:nnodes
                            y = [Y(i_cols_p,i_w_p);
                                 Y(i_cols_s,j);
                                 Y(i_cols_f,(j-1)*nnodes+k)];
                            [d1,jacobian] = dynamic_model(y,innovation,params,steady_state,i+1);
                            if i == 1
                                % in first period we don't keep track of
                                % predetermined variables
                                i_cols_A = [i_cols_As - ny; i_cols_Af];
                                A(i_rows,i_cols_A) = A(i_rows,i_cols_A) + weights(k)*jacobian(:,i_cols_1);
                            else
                                i_cols_A = [i_cols_Ap; i_cols_As; i_cols_Af];
                                A(i_rows,i_cols_A) = A(i_rows,i_cols_A) + weights(k)*jacobian(:,i_cols_j);
                            end
                            res(i_rows) = res(i_rows)+weights(k)*d1;
                            i_cols_Af = i_cols_Af + ny;
                        end
                    else
                        y = [Y(i_cols_p,i_w_p);
                             Y(i_cols_s,j);
                             Y(i_cols_f,j)];
                        [d1,jacobian] = dynamic_model(y,innovation,params,steady_state,i+1);
                        if i == 1
                            % in first period we don't keep track of
                            % predetermined variables
                            i_cols_A = [i_cols_As - ny; i_cols_Af];
                            A(i_rows,i_cols_A) = jacobian(:,i_cols_1);
                        else
                            i_cols_A = [i_cols_Ap; i_cols_As; i_cols_Af];
                            A(i_rows,i_cols_A) = jacobian(:,i_cols_j);
                        end
                        res(i_rows) = d1;
                        i_cols_Af = i_cols_Af + ny;
                    end
                    i_rows = i_rows + ny;
                    if mod(j,nnodes) == 0
                        i_w_p = i_w_p + 1;
                    end
                    if i > 1
                        if mod(j,nnodes) == 0
                            i_cols_Ap = i_cols_Ap + ny;
                        end
                        i_cols_As = i_cols_As + ny;
                    end
                end
                i_cols_p = i_cols_p + ny;
                i_cols_s = i_cols_s + ny;
                i_cols_f = i_cols_f + ny;
            elseif i == periods
                if i == order+2
                    i_cols_A = [i_cols_Ap; i_cols_As; i_cols_Af];
                end
                for j=1:world_nbr
                    [d1,jacobian] = dynamic_model(Y(i_cols,j),exo_simul, ...
                                                  params,steady_state,i+1);
                    A(i_rows,i_cols_A(i_cols_T)) = jacobian(:,i_cols_T);
                    res(i_rows) = d1;
                    i_rows = i_rows + ny;
                    i_cols_A = i_cols_A + ny;
                end
            else
                if i == order+2
                    i_cols_A = [i_cols_Ap; i_cols_As; i_cols_Af];
                end
                for j=1:world_nbr
                    [d1,jacobian] = dynamic_model(Y(i_cols,j), ...
                                                  exo_simul,params,steady_state,i+1);
                    A(i_rows,i_cols_A) = jacobian(:,i_cols_j);
                    res(i_rows) = d1;
                    i_rows = i_rows + ny;
                    i_cols_A = i_cols_A + ny;
                end
            end
            i_cols = i_cols + ny;
        end
        err = max(abs(res));
        if err < tolerance
            stop = 1 ;
            if verbose
                fprintf('\n') ;
                disp([' Total time of simulation        :' num2str(etime(clock,h1))]) ;
                fprintf('\n') ;
                disp([' Convergency obtained.']) ;
                fprintf('\n') ;
            end
            flag = 0;% Convergency obtained.
            endo_simul = Y(ny+(1:ny),1);
            break
        end
        dy = -A\res;
        Y(i_upd) =   Y(i_upd) + dy;
    end

    if ~stop
        if verbose
            fprintf('\n') ;
            disp(['     Total time of simulation        :' num2str(etime(clock,h1))]) ;
            fprintf('\n') ;
            disp(['WARNING : maximum number of iterations is reached (modify options_.maxit_).']) ;
            fprintf('\n') ;
        end
        flag = 1;% more iterations are needed.
        endo_simul = 1;
    end
    if verbose
        disp (['-----------------------------------------------------']) ;
    end