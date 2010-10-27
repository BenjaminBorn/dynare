/*
 * Copyright (C) 2007-2009 Dynare Team
 *
 * This file is part of Dynare.
 *
 * Dynare is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Dynare is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Dynare.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <cstring>
#include "Interpreter.hh"


#ifdef DEBUG_EX

using namespace std;
# include <sstream>

string
Get_Argument(const char *argv)
{
  string f(argv);
  return f;
}


#else

string
Get_Argument(const mxArray *prhs)
{
  const mxArray *mxa = prhs;
  int buflen = mxGetM(mxa) * mxGetN(mxa) + 1;
  char *first_argument;
  first_argument = (char *) mxCalloc(buflen, sizeof(char));
  int status = mxGetString(mxa, first_argument, buflen);
  if (status != 0)
    mexWarnMsgTxt("Not enough space. The first argument is truncated.");
  string f(first_argument);
  mxFree(first_argument);
  return f;
}
#endif

void
Get_Arguments_and_global_variables(int nrhs,
#ifndef DEBUG_EX
                                   const mxArray *prhs[],
#else
                                   const char *prhs[],
#endif
                                   int &count_array_argument,
                                   double *yd[], unsigned int &row_y, unsigned int &col_y,
                                   double *xd[], unsigned int &row_x, unsigned int &col_x,
                                   double *params[], unsigned int &periods,
#ifndef DEBUG_EX
                                   mxArray *block_structur[],
#endif
                                   bool &steady_state, bool &evaluate, int &block,
                                   mxArray *M_[], mxArray *oo_[], mxArray *options_[])
{
#ifdef DEBUG_EX
  for (int i = 2; i < nrhs; i++)
#else
  for (int i = 0; i < nrhs; i++)
#endif
    {
#ifndef DEBUG_EX
      if (!mxIsChar(prhs[i]))
        {
          switch (count_array_argument)
            {
            case 0:
              *yd = mxGetPr(prhs[i]);
              row_y = mxGetM(prhs[i]);
              col_y = mxGetN(prhs[i]);
              break;
            case 1:
              *xd =  mxGetPr(prhs[i]);
              row_x = mxGetM(prhs[i]);
              col_x = mxGetN(prhs[i]);
              break;
            case 2:
              *params = mxGetPr(prhs[i]);
              break;
            case 3:
              periods = mxGetScalar(prhs[i]);
              break;
            case 4:
              *block_structur = mxDuplicateArray(prhs[i]);
              break;
            default:
              //mexPrintf("Unknown argument count_array_argument=%d\n",count_array_argument);
              break;
            }
          count_array_argument++;
        }
      else
#endif
      if (Get_Argument(prhs[i]) == "static")
        steady_state = true;
      else if (Get_Argument(prhs[i]) == "dynamic")
        steady_state = false;
      else if (Get_Argument(prhs[i]) == "evaluate")
        evaluate = true;
      else
        {
          int pos = Get_Argument(prhs[i]).find("block");
          if (pos != (int)string::npos)
            {
              int pos1 = Get_Argument(prhs[i]).find("=", pos+5);
              if (pos1 != (int)string::npos)
                pos = pos1 + 1;
              else
                pos += 5;
              block =  atoi(Get_Argument(prhs[i]).substr(pos, string::npos).c_str())-1;
            }
          else
            {
              ostringstream tmp;
              tmp << " in main, unknown argument : " << Get_Argument(prhs[i]) << "\n";
              throw FatalExceptionHandling(tmp.str());
            }
        }
    }
  if (count_array_argument > 0 && count_array_argument < 4)
    {
      if (count_array_argument == 3 && steady_state)
        periods = 1;
      else
        {
          ostringstream tmp;
          tmp << " in main, missing arguments. All the following arguments have to be indicated y, x, params, it_\n";
          throw FatalExceptionHandling(tmp.str());
        }
    }
  *M_ = mexGetVariable("global", "M_");
  if (M_ == NULL)
    {
      ostringstream tmp;
      tmp << " in main, global variable not found: M_\n";
      throw FatalExceptionHandling(tmp.str());
    }
  /* Gets variables and parameters from global workspace of Matlab */
  *oo_ = mexGetVariable("global", "oo_");
  if (oo_ == NULL)
    {
      ostringstream tmp;
      tmp << " in main, global variable not found: oo_\n";
      throw FatalExceptionHandling(tmp.str());
    }
  *options_ = mexGetVariable("global", "options_");
  if (options_ == NULL)
    {
      ostringstream tmp;
      tmp << " in main, global variable not found: options_\n";
      throw FatalExceptionHandling(tmp.str());
    }
}

#ifdef DEBUG_EX
int
main(int nrhs, const char *prhs[])
#else
/* The gateway routine */
void
mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
#endif
{
  mxArray *M_, *oo_, *options_;
#ifndef DEBUG_EX
  mxArray *block_structur = NULL;
#else
  int nlhs = 0;
  char *plhs[1];
  load_global((char*)prhs[1]);
#endif
  //ErrorHandlingException error_handling;
  unsigned int i, row_y = 0, col_y = 0, row_x = 0, col_x = 0, nb_row_xd = 0;
  int steady_row_y, steady_col_y, steady_row_x, steady_col_x, steady_nb_row_xd;
  int y_kmin = 0, y_kmax = 0, y_decal = 0;
  unsigned int periods = 1;
  double *direction;
  bool steady_state = false;
  bool evaluate = false;
  int block = -1;
  double *params = NULL;
  double *yd = NULL, *xd = NULL;
  int count_array_argument = 0;

  try
    {
      Get_Arguments_and_global_variables(nrhs, prhs, count_array_argument,
                                   &yd, row_y, col_y,
                                   &xd, row_x, col_x,
                                   &params, periods,
#ifndef DEBUG_EX
                                   &block_structur,
#endif
                                   steady_state, evaluate, block,
                                   &M_, &oo_, &options_);
    }
  catch (GeneralExceptionHandling &feh)
    {
      DYN_MEX_FUNC_ERR_MSG_TXT(feh.GetErrorMsg().c_str());
    }


  if (!count_array_argument)
    params = mxGetPr(mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "params")));

  double *steady_yd = NULL, *steady_xd = NULL;
  if (!steady_state)
    {
      if (!count_array_argument)
        {
          yd = mxGetPr(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "endo_simul")));
          row_y = mxGetM(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "endo_simul")));
          col_y = mxGetN(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "endo_simul")));
          xd = mxGetPr(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_simul")));
          row_x = mxGetM(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_simul")));
          col_x = mxGetN(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_simul")));
        }
      nb_row_xd = int (floor(*(mxGetPr(mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "exo_det_nbr"))))));

      y_kmin = int (floor(*(mxGetPr(mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "maximum_lag"))))));
      y_kmax = int (floor(*(mxGetPr(mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "maximum_lead"))))));
      y_decal = max(0, y_kmin-int (floor(*(mxGetPr(mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "maximum_endo_lag")))))));
      if (!count_array_argument)
        periods = int (floor(*(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "periods"))))));

      steady_yd = mxGetPr(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "steady_state")));
      steady_row_y = mxGetM(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "steady_state")));
      steady_col_y = mxGetN(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "steady_state")));;
      steady_xd = mxGetPr(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_steady_state")));
      steady_row_x = mxGetM(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_steady_state")));
      steady_col_x = mxGetN(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_steady_state")));
      steady_nb_row_xd = int (floor(*(mxGetPr(mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "exo_det_nbr"))))));
    }
  else
    {
      if (!count_array_argument)
        {
          yd = mxGetPr(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "steady_state")));
          row_y = mxGetM(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "steady_state")));
          col_y = mxGetN(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "steady_state")));;

          xd = mxGetPr(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_steady_state")));
          row_x = mxGetM(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_steady_state")));
          col_x = mxGetN(mxGetFieldByNumber(oo_, 0, mxGetFieldNumber(oo_, "exo_steady_state")));
        }
      nb_row_xd = int (floor(*(mxGetPr(mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "exo_det_nbr"))))));
    }
  int maxit_ = int (floor(*(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "maxit_"))))));
  double slowc = double (*(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "slowc")))));
  double markowitz_c = double (*(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "markowitz")))));
  int minimal_solving_periods = int (*(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "minimal_solving_periods")))));
  int stack_solve_algo = int (*(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "stack_solve_algo")))));
  int solve_algo;
  double solve_tolf;
  if (steady_state)
     {
       solve_algo = int (*(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "solve_algo")))));
       solve_tolf = *(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "solve_tolf"))));
     }

  else
    {
      solve_algo = stack_solve_algo;
      solve_tolf = *(mxGetPr(mxGetFieldByNumber(options_, 0, mxGetFieldNumber(options_, "dynatol"))));
    }

  mxArray *mxa = mxGetFieldByNumber(M_, 0, mxGetFieldNumber(M_, "fname"));
  int buflen = mxGetM(mxa) * mxGetN(mxa) + 1;
  char *fname;
  fname = (char *) mxCalloc(buflen+1, sizeof(char));
  int status = mxGetString(mxa, fname, buflen);
  fname[buflen] = ' ';
  if (status != 0)
    mexWarnMsgTxt("Not enough space. Filename is truncated.");
  string file_name = fname;

  int size_of_direction = col_y*row_y*sizeof(double);
  double *y = (double *) mxMalloc(size_of_direction);
  double *ya = (double *) mxMalloc(size_of_direction);
  direction = (double *) mxMalloc(size_of_direction);
  memset(direction, 0, size_of_direction);
  double *x = (double *) mxMalloc(col_x*row_x*sizeof(double));
  for (i = 0; i < row_x*col_x; i++)
    x[i] = double (xd[i]);
  for (i = 0; i < row_y*col_y; i++)
    {
      y[i]  = double (yd[i]);
      ya[i] = double (yd[i]);
    }
  int y_size = row_y;
  int nb_row_x = row_x;
  clock_t t0 = clock();

  Interpreter interprete(params, y, ya, x, steady_yd, steady_xd, direction, y_size, nb_row_x, nb_row_xd, periods, y_kmin, y_kmax, maxit_, solve_tolf, size_of_direction, slowc, y_decal, markowitz_c, file_name, minimal_solving_periods, stack_solve_algo, solve_algo);

  string f(fname);
  mxFree(fname);
  int nb_blocks = 0;
  double *pind;
  bool result = true, no_error = true;

  try
    {
      result = interprete.compute_blocks(f, f, steady_state, evaluate, block, nb_blocks);
    }
  catch (GeneralExceptionHandling &feh)
    {
      DYN_MEX_FUNC_ERR_MSG_TXT(feh.GetErrorMsg().c_str());
    }

  clock_t t1 = clock();
  if (!steady_state && !evaluate && no_error)
    mexPrintf("Simulation Time=%f milliseconds\n", 1000.0*(double (t1)-double (t0))/double (CLOCKS_PER_SEC));
#ifndef DEBUG_EX
  bool dont_store_a_structure = false;
  if (nlhs > 0)
    {
      plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
      pind = mxGetPr(plhs[0]);
      if (no_error)
        pind[0] = 0;
      else
        pind[0] = 1;
      if (nlhs > 1)
        {
          if (block >= 0)
            {
              if (evaluate)
                {
                  vector<double> residual = interprete.get_residual();
                  plhs[1] = mxCreateDoubleMatrix(residual.size()/col_y, col_y, mxREAL);
                  pind = mxGetPr(plhs[1]);
                  for (i = 0; i < residual.size(); i++)
                    pind[i] = residual[i];
                }
              else
                {
                  plhs[1] = mxCreateDoubleMatrix(row_y, col_y, mxREAL);
                  pind = mxGetPr(plhs[1]);
                  for (i = 0; i < row_y*col_y; i++)
                    pind[i] = y[i];
                }
            }
          else
            {
              plhs[1] = mxCreateDoubleMatrix(row_y, col_y, mxREAL);
              pind = mxGetPr(plhs[1]);
              if (evaluate)
                for (i = 0; i < row_y*col_y; i++)
                  pind[i] = y[i]-ya[i];
              else
                for (i = 0; i < row_y*col_y; i++)
                   pind[i] = y[i];
            }
          if (nlhs > 2)
            {
              int jacob_field_number = 0, jacob_exo_field_number = 0, jacob_exo_det_field_number = 0, jacob_other_endo_field_number = 0;
              if (!block_structur)
                {
                  const char *field_names[] = {"jacob","jacob_exo","jacob_exo_det","jacob_other_endo"};
                  jacob_field_number=0;
                  jacob_exo_field_number=1;
                  jacob_exo_det_field_number=2;
                  jacob_other_endo_field_number=2;
                  mwSize dims[1] = {nb_blocks };
                  block_structur = plhs[2] = mxCreateStructArray(1, dims, 4, field_names);
                }
              else if (!mxIsStruct(block_structur))
                if (block >=0 )
                  {

                    block_structur = plhs[2] = mxDuplicateArray(interprete.get_jacob(0));
                    //mexCallMATLAB(0,NULL, 1, &block_structur, "disp");
                    dont_store_a_structure = true;
                  }
                else
                  DYN_MEX_FUNC_ERR_MSG_TXT("Fatal error in bytecode: in main, the third output argument must be a structure\n");
              else
                {
                  jacob_field_number = mxAddField(block_structur, "jacob");
                  if (jacob_field_number == -1)
                    DYN_MEX_FUNC_ERR_MSG_TXT("Fatal error in bytecode: in main, cannot add extra field jacob to the structArray\n");
                  jacob_exo_field_number = mxAddField(block_structur, "jacob_exo");
                  if (jacob_exo_field_number == -1)
                    DYN_MEX_FUNC_ERR_MSG_TXT("Fatal error in bytecode: in main, cannot add extra field jacob_exo to the structArray\n");
                  jacob_exo_det_field_number = mxAddField(block_structur, "jacob_exo_det");
                  if (jacob_exo_det_field_number == -1)
                    DYN_MEX_FUNC_ERR_MSG_TXT("Fatal error in bytecode: in main, cannot add extra field jacob_exo_det to the structArray\n");
                  jacob_other_endo_field_number = mxAddField(block_structur, "jacob_other_endo");
                  if (jacob_other_endo_field_number == -1)
                    DYN_MEX_FUNC_ERR_MSG_TXT("Fatal error in bytecode: in main, cannot add extra field jacob_other_endo to the structArray\n");
                }
              if (!dont_store_a_structure)
                {
                  for (int i = 0; i < nb_blocks; i++)
                   {
                      mxSetFieldByNumber(block_structur,i,jacob_field_number,interprete.get_jacob(i));
                      mxSetFieldByNumber(block_structur,i,jacob_exo_field_number,interprete.get_jacob_exo(i));
                      mxSetFieldByNumber(block_structur,i,jacob_exo_det_field_number,interprete.get_jacob_exo_det(i));
                      mxSetFieldByNumber(block_structur,i,jacob_other_endo_field_number,interprete.get_jacob_other_endo(i));
                    }
                  plhs[2] = block_structur;
                }
              if (nlhs > 3)
                {
                  plhs[3] = mxCreateDoubleMatrix(row_y, col_y, mxREAL);
                  pind = mxGetPr(plhs[3]);
                  for (i = 0; i < row_y*col_y; i++)
                    pind[i] = y[i];
                }
            }
        }
    }
#else
  Free_global();
#endif
  if (x)
    mxFree(x);
  if (y)
    mxFree(y);
  if (ya)
    mxFree(ya);
  if (direction)
    mxFree(direction);
}
