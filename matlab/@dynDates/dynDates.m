function date = dynDates(a)

%@info:
%! @deftypefn {Function File} {@var{date} =} dynDate (@var{a})
%! @anchor{dynDates}
%! @sp 1
%! Constructor for the Dynare dates class.
%! @sp 2
%! @strong{Inputs}
%! @sp 1
%! @table @ @var
%! @item a
%! Date. For Quaterly, Monthly or Weekly data, a must be a string. For yearly data or if the frequence is not
%! defined  must be an integer. If @var{a} is a dynDates object, then date will be a copy of this object. If
%! the constructor is called without input argument, it will return an empty dynDates object.
%! @end table
%! @sp 1
%! @strong{Outputs}
%! @sp 1
%! @table @ @var
%! @item date
%! Dynare date object.
%! @end table
%! @sp 1
%! @strong{Properties}
%! @sp 1
%! The constructor defines the following properties:
%! @sp 1
%! @item freq
%! Scalar integer, the frequency of the time series. @var{freq} is equal to 1 if data are on a yearly basis or if
%! frequency is unspecified. @var{freq} is equal to 4 if data are on a quaterly basis. @var{freq} is equal to
%! 12 if data are on a monthly basis. @var{freq} is equal to 52 if data are on a weekly basis.
%! @item time
%! Row vector of integers (1*2) indicating the year and the week, month or quarter of the first observation.
%! @end table
%! @sp 1
%! @strong{This function is called by:}
%! @sp 2
%! @strong{This function calls:}
%! @ref{set_time}
%!
%! @end deftypefn
%@eod:

% Copyright (C) 2011 Dynare Team
% stephane DOT adjemian AT univ DASH lemans DOT fr
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

date = struct;

date.freq = NaN;
date.time = NaN(1,2);

date = class(date,'dynDates');

switch nargin
  case 0
    return
  case 1
    if ischar(a)% Weekly, Monthly or Quaterly data.
        quaterly = findstr('Q',a);
        monthly  = findstr('M',a);
        weekly   = findstr('W',a);
        if ~isempty(quaterly)
            date.freq = 4;
            date.time(1) = str2num(a(1:quaterly-1));
            date.time(2) = str2num(a(quaterly+1:end));
        end
        if ~isempty(monthly)
            date.freq = 12;
            date.time(1) = str2num(a(1:monthly-1));
            date.time(2) = str2num(a(monthly+1:end));
        end
        if ~isempty(weekly)
            date.freq = 52;
            date.time(1) = str2num(a(1:weekly-1));
            date.time(2) = str2num(a(weekly+1:end));
        end
        if isempty(quaterly) && isempty(monthly) && isempty(weekly)
            error('dynDates:: Using a string as an input argument, I can only handle weekly (W), monthly (M) or quaterly (Q) data!');
        end
    elseif isa(a,'dynDates') % If input argument is a dynDates object then do a copy.
        date = a;
    else% If b is not a string then yearly data are assumed.
        date.freq = 1;
        date.time(1) = a;
        date.time(2) = 1;
    end
  otherwise
    error('dynDates:: Can''t instantiate the class, wrong calling sequence!')
end

%@test:1
%$ addpath ../matlab
%$
%$ % Define some dates
%$ date_1 = 1950;
%$ date_2 = '1950Q2';
%$ date_3 = '1950M10';
%$ date_4 = '1950W50';
%$
%$ % Define expected results.
%$ e_date_1 = [1950 1];
%$ e_freq_1 = 1;
%$ e_date_2 = [1950 2];
%$ e_freq_2 = 4;
%$ e_date_3 = [1950 10];
%$ e_freq_3 = 12;
%$ e_date_4 = [1950 50];
%$ e_freq_4 = 52;
%$
%$ % Call the tested routine.
%$ d1 = dynDates(date_1);
%$ d2 = dynDates(date_2);
%$ d3 = dynDates(date_3);
%$ d4 = dynDates(date_4);
%$
%$ % Check the results.
%$ t(1) = dyn_assert(d1.time,e_date_1);
%$ t(2) = dyn_assert(d2.time,e_date_2);
%$ t(3) = dyn_assert(d3.time,e_date_3);
%$ t(4) = dyn_assert(d4.time,e_date_4);
%$ t(5) = dyn_assert(d1.freq,e_freq_1);
%$ t(6) = dyn_assert(d2.freq,e_freq_2);
%$ t(7) = dyn_assert(d3.freq,e_freq_3);
%$ t(8) = dyn_assert(d4.freq,e_freq_4);
%$ T = all(t);
%@eof:1
