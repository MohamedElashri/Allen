#include "UTFastFitter.cuh" 

__host__ __device__
float fastfitter(
  BestParams best_params, 
  const MiniState& velo_state, 
  float improvedParams[4], 
  const float qpxz2p,
  const float* ut_dxDy)
{
    
  const float ty        = velo_state.ty;
    const float zKink     = magFieldParams[0] - ty*ty*magFieldParams[1] - ty*ty*ty*ty*magFieldParams[2];
    const float xMidField = velo_state.x + velo_state.tx*(zKink-velo_state.z);

    const float zDiff     = 0.001f * (zKink - UT::Constants::zMidUT);

    // -- This is to avoid division by zero...
    const float pHelper   = std::max( float(std::abs(best_params.qp * qpxz2p)), float(1e-9));
    const float invP      = pHelper*vdt::fast_isqrtf(1.0f+ty*ty);
    
    // these resolution are semi-empirical, could be tuned and might not be correct for low momentum.
    const float error1    = 0.14f + 10000.0f*invP; // this is the resolution due to multiple scattering between Velo and UT
    const float error2    = 0.12f + 3000.0f*invP;  // this is the resolution due to the finite Velo resolution
    const float error     = error1*error1 + error2*error2;
    const float weight    = 1.0f/error;
    
    float mat[6]          = {weight, weight * zDiff, weight * zDiff * zDiff, 0.0f, 0.0f, 0.0f};
    float rhs[3]          = {weight * xMidField, weight * xMidField * zDiff, 0.0f };

    const float yyProto = velo_state.y - velo_state.ty * velo_state.z;
    
    for (int i = 0; i < UT::Constants::n_layers; ++i) {
      if (best_hits[i] != -1) {
        const auto hit = best_hits[i];
        
        // check: is the ui calculated correctly?
        //const float ui = hit->x;
        // check: is this plane code correct?
        const int plane_code = i;
        const float dxDy = ut_dxDy[plane_code];
        const float yy = yyProto + (velo_state.ty * ut_hits.zAtYEq0[hit]);
        const float ui = ut_hits.xAt(hit, yy, dxDy);
        const float dz = 0.001f * (ut_hits.zAtYEq0[hit] - UT::Constants::zMidUT);
        const float w = ut_hits.weight[hit];  
        
        const float t = ut_hits.sinT(hit, dxDy); 
        
        mat[0] += w;
        mat[1] += w * dz;
        mat[2] += w * dz * dz;
        mat[3] += w * t;
        mat[4] += w * dz * t;
        mat[5] += w * t * t;
        rhs[0] += w * ui;
        rhs[1] += w * ui * dz;
        rhs[2] += w * ui * t;
      }
    }

    // ROOT::Math::CholeskyDecomp<float, 3> decomp(mat);
    // if (UNLIKELY(!decomp)){
    //   return best_params.qp;
    // }else{
    //   decomp.Solve(rhs);
    // }

    const float xSlopeUTFit = 0.001f * rhs[1];
    const float xUTFit      = rhs[0];
    const float offsetY     = rhs[2];

    const float distX = (xMidField - xUTFit  - xSlopeUTFit*(zKink - UT::Constants::zMidUT));
    // -- This takes into account that the distance between a point and track is smaller than the distance on the x-axis
    const float distCorrectionX2 = 1.0f/(1 + xSlopeUTFit*xSlopeUTFit);
    float chi2 = weight * (distX*distX*distCorrectionX2 + offsetY*offsetY/(1.0f + ty*ty));
    
    for (int i = 0; i < UT::Constants::n_layers; ++i) {
      if (best_hits[i] != -1) {
        const auto hit = best_hits[i];
        
        const float   w  = ut_hits.weight[hit];  
        const float   dz = ut_hits.zAtYEq0[hit] - UT::Constants::zMidUT;
        // check: is this plane code correct?
        const int plane_code = i;
        const float dxDy = ut_dxDy[plane_code];
        const float yy = yyProto + (velo_state.ty * ut_hits.zAtYEq0[hit]);
        const float x = ut_hits.xAt(hit, yy, dxDy);
        const float dist = (x - xUTFit - xSlopeUTFit*dz - offsetY * ut_hits.sinT(hit,dxDy));
        chi2 += w * dist * dist * distCorrectionX2;
      }
    }

    // new VELO slope x
    const float xb = 0.5f*((xUTFit + xSlopeUTFit * (zKink - UT::Constants::zMidUT)) + xMidField); // the 0.5 is empirical
    const float xSlopeVeloFit = (xb - velo_state.x) / (zKink - velo_state.z);
    
    improvedParams = { xUTFit, xSlopeUTFit, velo_state.y + velo_state.ty*(UT::Constants::zMidUT-velo_state.z) + offsetY, chi2 };
    
    // calculate q/p
    const float sinInX = xSlopeVeloFit * vdt::fast_isqrtf(1.0f + xSlopeVeloFit * xSlopeVeloFit + ty * ty);
    const float sinOutX = xSlopeUTFit * vdt::fast_isqrtf(1.0f  + xSlopeUTFit * xSlopeUTFit     + ty * ty);
    return (sinInX - sinOutX);
}
