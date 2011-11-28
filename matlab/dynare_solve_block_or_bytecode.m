function [x,info] = dynare_solve_block_or_bytecode(y, exo, params, options, M)
% Copyright (C) 2010-2011 Dynare Team
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

info = 0;
x = y;
if options.block && ~options.bytecode
    for b = 1:size(M.blocksMFS,1)
        n = size(M.blocksMFS{b}, 1);
        ss = x;
        if n ~= 0
            if options.solve_algo <= 4
                [y, check] = dynare_solve('block_mfs_steadystate', ...
                                          ss(M.blocksMFS{b}), ...
                                          options.jacobian_flag, b, ss, exo, params, M);
                if check ~= 0
                    error(['STEADY: convergence problems in block ' int2str(b)])
                end
                ss(M.blocksMFS{b}) = y;
            else
                [ss, check] = solve_one_boundary([M.fname '_static_' int2str(b)], ss, exo, ...
                                                 params, [], M.blocksMFS{b}, n, 1, 0, b, 0, options.maxit_, ...
                                                 options.solve_tolf, options.slowc, 0, options.solve_algo, 1, 0, 0,M,options);
                
            end
        end
        [r, g1, x] = feval([M.fname '_static'], b, ss, ...
                           exo, params);
    end
elseif options.bytecode
    if options.solve_algo > 4
        [check, x] = bytecode('static', x, exo, params);
        mexErrCheck('bytecode', check);
        info = check;
    elseif options.block
        for b = 1:size(M.blocksMFS,1)
            n = size(M.blocksMFS{b}, 1);
            if n ~= 0
                [y, check] = dynare_solve('block_bytecode_mfs_steadystate', ...
                                          x(M.blocksMFS{b}), ...
                                          options.jacobian_flag, b, x, exo, params, M);
                if check ~= 0
                    error(['STEADY: convergence problems in block ' int2str(b)])
                end
                x(M.blocksMFS{b}) = y;
            else
                [chk, nulldev, nulldev1, x] = bytecode( x, exo, params, x, 1, x, 'evaluate', 'static', ['block = ' int2str(b)]);
            end;
        end
    else
        [x, check] = dynare_solve('bytecode_steadystate', ...
                                  y, ...
                                  options.jacobian_flag, exo, params);
        if check ~= 0
            error('STEADY: convergence problems')
        end
    end
end