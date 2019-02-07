#include "SciFiParametrization.h"
#include "Logger.h"

#include <fstream>     // std::cout, std::ios

/*
  Author: Pierre Billoir
  Date: 01/2018

  01/2018 converted to C++, adopted to Allen use case by Dorothea vom Bruch
  
 */


int Coef::Read(FILE *inp, int degx1, int degx2, int degy1, int degy2) {
    double a;
    Degx1 = degx1; Degx2 = degx2; Degy1 = degy1; Degy2 = degy2;
    for(int i=0; i<degx2; i++) { fscanf(inp,"%lf",&a); x00.push_back(a); }
    for(int i=0; i<degx2; i++) { fscanf(inp,"%lf",&a); tx00.push_back(1e-3*a); }
    for(int i=0; i<degx1; i++) { fscanf(inp,"%lf",&a); x10.push_back(a); }
    for(int i=0; i<degx1; i++) { fscanf(inp,"%lf",&a); x01.push_back(a); }
    for(int i=0; i<degx1; i++) { fscanf(inp,"%lf",&a); tx10.push_back(1e-3*a); }
    for(int i=0; i<degx1; i++) { fscanf(inp,"%lf",&a); tx01.push_back(1e-3*a); }

    for(int i=0; i<degy2; i++) { fscanf(inp,"%lf",&a); y00.push_back(a); }
    for(int i=0; i<degy2; i++) { fscanf(inp,"%lf",&a); ty00.push_back(1e-3*a); }
    for(int i=0; i<degy1; i++) { fscanf(inp,"%lf",&a); y10.push_back(a); }
    for(int i=0; i<degy1; i++) { fscanf(inp,"%lf",&a); y01.push_back(a); }
    for(int i=0; i<degy1; i++) { fscanf(inp,"%lf",&a); ty10.push_back(1e-3*a); }
    for(int i=0; i<degy1; i++) { fscanf(inp,"%lf",&a); ty01.push_back(1e-3*a); }
    if(feof(inp)) return 0;
    return 1;
  }

Coef operator+(Coef a, Coef b)
{
  Coef c = a;
  //c.Degx1 = a.Degx1; c.Degx2 = a.Degx2; c.Degy1 = a.Degy1; c.Degy2 = a.Degy2;
  for(int i=0; i<c.Degx2; i++) { c.x00[i] += b.x00[i]; c.tx00[i] += b.tx00[i]; }
  for(int i=0; i<c.Degx1; i++) { c.x10[i] += b.x10[i]; c.x01[i] += b.x01[i]; c.tx10[i] += b.tx10[i]; c.tx01[i] += b.tx01[i]; }
  for(int i=0; i<c.Degy2; i++) { c.y00[i] += b.y00[i]; c.ty00[i] += b.ty00[i]; }
  for(int i=0; i<c.Degy1; i++) { c.y10[i] += b.y10[i]; c.y01[i] += b.y01[i]; c.ty10[i] += b.ty10[i]; c.ty01[i] += b.ty01[i]; }
  return c;
}

Coef operator-(Coef a, Coef b)
{
  Coef c = a;
  //c.Degx1 = a.Degx1; c.Degx2 = a.Degx2; c.Degy1 = a.Degy1; c.Degy2 = a.Degy2;
  for(int i=0; i<c.Degx2; i++) { c.x00[i] -= b.x00[i]; c.tx00[i] -= b.tx00[i]; }
  for(int i=0; i<c.Degx1; i++) { c.x10[i] -= b.x10[i]; c.x01[i] -= b.x01[i]; c.tx10[i] -= b.tx10[i]; c.tx01[i] -= b.tx01[i]; }
  for(int i=0; i<c.Degy2; i++) { c.y00[i] -= b.y00[i]; c.ty00[i] -= b.ty00[i]; }
  for(int i=0; i<c.Degy1; i++) { c.y10[i] -= b.y10[i]; c.y01[i] -= b.y01[i]; c.ty10[i] -= b.ty10[i]; c.ty01[i] -= b.ty01[i]; }
  return c;
}

Coef operator*(Coef a, double p)
{
  Coef c = a;
  //c.Degx1 = a.Degx1; c.Degx2 = a.Degx2; c.Degy1 = a.Degy1; c.Degy2 = a.Degy2;
  for(int i=0; i<c.Degx2; i++) { c.x00[i] *= p; c.tx00[i] *= p; }
  for(int i=0; i<c.Degx1; i++) { c.x10[i] *= p; c.x01[i] *= p; c.tx10[i] *= p; c.tx01[i] *= p; }
  for(int i=0; i<c.Degy2; i++) { c.y00[i] *= p; c.ty00[i] *= p; }
  for(int i=0; i<c.Degy1; i++) { c.y10[i] *= p; c.y01[i] *= p; c.ty10[i] *= p; c.ty01[i] *= p; }
  return c;
}

SciFi::Parameters::Parameters(const char *name) {
  FILE *coef;
  coef = fopen(name,"r");
  
  fscanf(coef,"%lf %lf %lf %lf %lf %lf %lf",&ZINI,&ZFIN,&PMIN,&BENDX,&BENDX_X2,&BENDX_Y2,&BENDY_XY);
  fscanf(coef, "%lf %lf %lf %lf", &Txmax,&Tymax,&XFmax,&Dtxy);
  fscanf(coef,"%d %d %d %d %d %d %d %d",&Nbinx,&Nbiny,&XGridOption,&YGridOption,&DEGX1,&DEGX2,&DEGY1,&DEGY2);

  debug_cout << "ZINI,ZFIN " << ZINI << " " << ZFIN << std::endl;;
  debug_cout << "PMIN " << PMIN << std::endl;;
  debug_cout << "BENDX " << BENDX << " BENDX_X2 " << BENDX_X2 << " BENDX_Y2 " << BENDX_Y2 << " BENDY_XY " << BENDY_XY << std::endl;
  debug_cout << "Txmax " << Txmax << " Tymax " << Tymax << " XFmax " << XFmax << " Dtxy " << Dtxy << std::endl; 
  debug_cout << "Nbinx " << Nbinx << " Nbiny " << Nbiny << std::endl;
  debug_cout << "GridOptions " << XGridOption << " " << YGridOption << std::endl;
  debug_cout << "DEGX1 " << DEGX1 << " DEGX2 " << DEGX2 << " DEGY1 " << DEGY1 << " DEGY2 " << DEGY2 << std::endl;
  debug_cout << "bending at ZINI " << BENDX << " rad.MeV " << std::endl;

  for(int ix=0; ix<Nbinx; ix++) for(int iy=0; iy<Nbiny; iy++) C[ix][iy].Read(coef,DEGX1,DEGX2,DEGY1,DEGY2);

   Xmax = ZINI*Txmax; 
   Ymax = ZINI*Tymax;
}

int extrap(const float xi,const float yi,const float txi,const float tyi,const float qop, const SciFi::Parameters& params, float& xf,float& yf,float& txf,float& tyf, float& der_xf_qop)
// extrapolation from plane zi to plane zf, from initial state (xi,yi,txi,tyi,qop) to final state (xf,yf,txf,tyf)
// the bending from origin to zi is approximated by adding (bend+bendx_x2*u^2+bendx_y2*v^2)*qop to u=xi/zi and bendy_xy*u*v*qop to v=yi/zi
// quad_inperp (logical): if true, the quadratic interpolation is used (better, with a little bit more computations)
// XGridO[tion and YGridOption describe the choice of xy grid. By default, it is 1 (equally spaced values)   
{
  const float zi = params.ZINI;
  const float zf = params.ZFIN;
  
  float xx,yy,dx,dy,ux,uy;
  int ix,iy;
  if(fabs(xi)>params.Xmax||fabs(yi)>params.Ymax) return 0;
  switch(params.XGridOption) {
    case 1: xx = xi/params.Xmax; break;
    case 2: xx = sqr(xi/params.Xmax); if(xi<0) xx = -xx; break;
    case 3: xx = xi/params.Xmax; xx = xx*xx*xx; break;
    case 4: xx = asin(xi/params.Xmax)*2/M_PI; break;
  }
  switch(params.YGridOption) {
    case 1: yy = yi/params.Ymax; break;
    case 2: yy = sqr(yi/params.Ymax); if(yi<0) yy = -yy; break;
    case 3: yy = yi/params.Ymax; yy = yy*yy*yy; break;
    case 4: yy = asin(yi/params.Ymax)*2/M_PI; break;
  }
  dx = params.Nbinx*(xx+1)/2; ix = dx; dx -= ix;
  dy = params.Nbiny*(yy+1)/2; iy = dy; dy -= iy;

  //ux = (txi-xi/zi-bend*qop)/params.Dtxy; uy = (tyi-yi/zi)/params.Dtxy;
  double bendx = params.BENDX+params.BENDX_X2*sqr(xi/zi)+params.BENDX_Y2*sqr(yi/zi);           
  double bendy = params.BENDY_XY*(xi/zi)*(yi/zi);                                
  ux = (txi-xi/zi-bendx*qop)/params.Dtxy; uy = (tyi-yi/zi-bendy*qop)/params.Dtxy; 
  if(fabs(ux)>2||fabs(uy)>2) return 0;

  Coef c;

  if(params.QuadraticInterpolation) {
    float gx,gy;
    gx = dx-.5; gy = dy-.5;
    //if(gx*gx+gy*gy>.01) return 0;
    if(ix==0) { ix = 1; gx -= 1.; }
    if(ix==params.Nbinx-1) { ix = params.Nbinx-2; gx += 1.; }
    if(iy==0) { iy = 1; gy -= 1.; }
    if(iy==params.Nbiny-1) { iy = params.Nbiny-2; gy += 1.; }

    int rx,ry,sx,sy;
    rx = (gx>=0); sx = 2*rx-1; ry = (gy>=0); sy = 2*ry-1;
    Coef c00,cp0,c0p,cn0,c0n,cadd;
    c00 = params.C[ix][iy]; cp0 = params.C[ix+1][iy]; c0p = params.C[ix][iy+1]; c0n = params.C[ix][iy-1]; cn0 = params.C[ix-1][iy];
    cadd = params.C[ix+sx][iy+sy];
    float gxy = gx*gy, gx2 = gx*gx, gy2 = gy*gy, g2 = gx*gx+gy*gy;
    c = c00*(1-g2) + (cp0*(gx2+gx) + cn0*(gx2-gx) + c0p*(gy2+gy) + c0n*(gy2-gy))*.5
      + ((c00+cadd)*sx*sy - cp0*rx*sy + cn0*(!rx)*sy - c0p*ry*sx + c0n*(!ry)*sx)*gxy;
  }
  else {
    float ex,fx,ey,fy;
    int jx,jy;
    if(dx<.5) { jx = ix-1; ex = .5+dx; fx = .5-dx; } else { jx = ix+1; ex = 1.5-dx; fx = dx-.5; }
    if(dy<.5) { jy = iy-1; ey = .5+dy; fy = .5-dy; } else { jy = iy+1; ey = 1.5-dy; fy = dy-.5; }
    if(ix<0||ix>=params.Nbinx||iy<0||iy>=params.Nbiny || jx<0||jx>=params.Nbinx||jy<0||jy>=params.Nbiny) return 0;
    Coef c_ii = params.C[ix][iy], c_ij = params.C[ix][jy], c_ji = params.C[jx][iy], c_jj = params.C[jx][jy];
    //printf("x00 %f %f %f %f\n",c_ii.x00[0],c_ij.x00[0],c_ji.x00[0],c_jj.x00[0]);
    c = c_ii*ex*ey + c_ij*ex*fy + c_ji*fx*ey + c_jj*fx*fy;
  }
  // straight line
  xf = xi+txi*(zf-zi);
  yf = yi+tyi*(zf-zi);
  txf = txi;
  tyf = tyi;
  // corrections to straight line
  der_xf_qop = 0; 
  float fq = qop*params.PMIN;
  float ff = 1.f;
  for(int deg=0; deg<c.Degx2; deg++) {
    double coef = c.x00[deg]; if(deg<c.Degx1) coef += c.x10[deg]*ux+c.x01[deg]*uy;
    der_xf_qop += (deg+1)*coef*ff; 
    ff *= fq;
    xf  += c.x00[deg]*ff;
    txf += c.tx00[deg]*ff;
    if(deg>=c.Degx1) continue;
    xf  += ( c.x10[deg]*ux +  c.x01[deg]*uy)*ff;
    txf += (c.tx10[deg]*ux + c.tx01[deg]*uy)*ff;
  }
  der_xf_qop *= params.PMIN;  
  ff = 1.f;
  for(int deg=0; deg<c.Degy2; deg++) {
    ff *= fq;
    yf  +=  c.y00[deg]*ff;
    tyf += c.ty00[deg]*ff;
    if(deg>=c.Degy1) continue;
    yf  += ( c.y10[deg]*ux +  c.y01[deg]*uy)*ff;
    tyf += (c.ty10[deg]*ux + c.ty01[deg]*uy)*ff;
  }
  return 1;
}

int update_qop_estimate(const MiniState& UT_state, const float qop, const float xhit, const SciFi::Parameters& params, const float xf_ini, const float yf_ini, const float txf_ini, const float tyf_ini, const float der_xf_qop_ini, float& qop_update)
{
  float r_prev = qop;
  float xf = xf_ini;
  float yf = yf_ini;
  float txf = txf_ini;
  float tyf = tyf_ini;
  float der_xf_qop = der_xf_qop_ini;
  //debug_cout << "starting iterations for new track" << std::endl;
  for ( int i = 0; i < MAXITER; ++i ) {
    if ( i > 0 ) {
      int ret = extrap(
        UT_state.x, UT_state.y,
        UT_state.tx, UT_state.ty,
        r_prev, params,
        xf, yf, txf, tyf, der_xf_qop);
      if ( !ret ) return 0;
    }
    qop_update = r_prev + (xhit - xf) / der_xf_qop;
    //debug_cout << "at iteration " << i << ": r_prev = " << std::setprecision(6) << r_prev << ", current r = " << qop_update << ", r difference = " << qop_update-r_prev << ", xf = " << xf << ", xhit = " << xhit << std::endl;
    //debug_cout << "der_xf_qop = " << der_xf_qop << std::endl;
    if ( std::abs(xf-xhit) < XCONVERGENCE )
      return 1;
    r_prev = qop_update;
  }
  return 0;
}
