#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <vector>

#include "MiniState.cuh"
#include "Logger.h"

/*
  Author: Pierre Billoir
  Date: 01/2018

 */
using namespace std;

#define sqr(x) ((x) * (x))

static constexpr int NBINXMAX = 100;
static constexpr int NBINYMAX = 100;
static constexpr int NSTEP = 50;
static constexpr int TWODIPOLES = 0;
static constexpr int MAXITER = 4;
static constexpr float RCONVERGENCE = 0.0001;
static constexpr float XCONVERGENCE = 1.;

class Coef {
public:
  int Degx1, Degx2, Degy1, Degy2;
  vector<double> x00, x10, x01, tx00, tx10, tx01, y00, y10, y01, ty00, ty10, ty01;
  Coef() {};
  ~Coef() {};
  int Read(FILE* inp, int degx1, int degx2, int degy1, int degy2);
};
Coef operator+(Coef a, Coef b);

Coef operator-(Coef a, Coef b);

Coef operator*(Coef a, double p);

namespace SciFi {
  struct Parameters {

    Parameters() {};
    Parameters(const char* name);

    double ZINI, ZFIN, PMIN, BENDX, BENDX_X2, BENDX_Y2, BENDY_XY, Txmax, Tymax, XFmax, Xmax, Ymax, Dtxy, step;
    int Nbinx, Nbiny, XGridOption, YGridOption, QuadraticInterpolation, DEGX1, DEGX2, DEGY1, DEGY2;
    Coef C[NBINXMAX][NBINYMAX];
  };

} // namespace SciFi
/*************************************************************************/

/*-------------------------------------------------------------------------------------------------------------------------*/
int extrap(
  const float xi,
  const float yi,
  const float txi,
  const float tyi,
  const float qop,
  const SciFi::Parameters& params,
  float& xf,
  float& yf,
  float& txf,
  float& tyf,
  float& der_xf_qop);

int update_qop_estimate(
  const MiniState& UT_state,
  const float qop,
  const float xhit,
  const SciFi::Parameters& params,
  const float xf_ini,
  const float yf_ini,
  const float txf_ini,
  const float tyf_ini,
  const float der_xf_qop_ini,
  float& qop_update);
