function [a,b] = size(c,dim)

% Copyright (C) 2013 Dynare Team
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

a = c.nobs;
b = c.vobs;

if nargin>1
    if nargout>1
        error('dseries::size: Wrong calling sequence!')
    end
    switch dim
      case 1
        a = c.nobs;
      case 2
        a = c.vobs;
      otherwise
        error(['dseries::size: Wrong calling sequence! Argument ''' inputname(2) ''' must be equal to 1 or 2.' ])
    end
else
    a = c.nobs;
    b = c.vobs;
end