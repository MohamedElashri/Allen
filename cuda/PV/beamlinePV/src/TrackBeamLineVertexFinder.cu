#include "TrackBeamLineVertexFinder.cuh"

__host__ __device__ PVTrack::PVTrack(const KalmanVeloState& state, float dz) :
  z {state.z + dz}, x {state.x + dz * state.tx, state.y + dz * state.ty}, tx {state.tx, state.ty}
{

  float state_tmp_c00 = state.c00;
  float state_tmp_c11 = state.c11;

  float dz2 = dz * dz;

  // TODO: check if fabsf is needed here
  state_tmp_c00 += dz2 * state.c22 + 2.f * fabsf(dz * state.c20);
  state_tmp_c11 += dz2 * state.c33 + 2.f * fabsf(dz * state.c31);
  W_00 = 1.f / state_tmp_c00;
  W_11 = 1.f / state_tmp_c11;
}
