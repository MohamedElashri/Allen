/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "pv_beamline_histo.cuh"

INSTANTIATE_ALGORITHM(pv_beamline_histo::pv_beamline_histo_t)

void pv_beamline_histo::pv_beamline_histo_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_zhisto_t>(arguments, first<host_number_of_events_t>(arguments) * (m_zmax - m_zmin) / m_dz);
}

void pv_beamline_histo::pv_beamline_histo_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_zhisto_t>(arguments, 0, context);

  global_function(pv_beamline_histo)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    constants.dev_beamline.data(),
    m_Nbins,
    m_zmin,
    m_zmax,
    m_maxTrackBlChi2,
    m_dz,
    m_SMOG2_pp_separation,
    m_SMOG2_maxTrackZ0Err,
    m_pp_maxTrackZ0Err,
    m_order_polynomial);
}

__device__ float gauss_integral(float x, int order_polynomial)
{
  const float a = sqrtf(float(2 * order_polynomial + 3));
  const float xi = x / a;
  const float eta = 1.f - xi * xi;
  constexpr float p[] = {0.5f, 0.25f, 0.1875f, 0.15625f};
  // be careful: if you choose here one order more, you also need to choose 'a' differently (a(N)=sqrt(2N+3))
  return 0.5f + xi * (p[0] + eta * (p[1] + eta * p[2]));
}

__global__ void pv_beamline_histo::pv_beamline_histo(
  pv_beamline_histo::Parameters parameters,
  float* dev_beamline,
  const int Nbins,
  const float zmin,
  const float zmax,
  const float maxTrackBlChi2,
  const float dz,
  const float SMOG2_pp_separation,
  const float SMOG2_maxTrackZ0Err,
  const float pp_maxTrackZ0Err,
  const int order_polynomial)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto velo_tracks_view = parameters.dev_velo_tracks_view[event_number];
  float* histo_base_pointer = parameters.dev_zhisto + Nbins * event_number;

  for (unsigned index = threadIdx.x; index < velo_tracks_view.size(); index += blockDim.x) {
    PVTrack trk = parameters.dev_pvtracks[velo_tracks_view.offset() + index];
    // apply the z cut here
    if (zmin < trk.z && trk.z < zmax) {
      const float diffx2 = (trk.x.x - dev_beamline[0]) * (trk.x.x - dev_beamline[0]);
      const float diffy2 = (trk.x.y - dev_beamline[1]) * (trk.x.y - dev_beamline[1]);
      const float blchi2 = diffx2 * trk.W_00 + diffy2 * trk.W_11;
      if (blchi2 >= maxTrackBlChi2) continue;

      // bin in which z0 is, in floating point
      const float zbin = (trk.z - zmin) / dz;

      // to compute the size of the window, we use the track
      // errors. eventually we can just parametrize this as function of
      // track slope.
      const float zweight = trk.tx.x * trk.tx.x * trk.W_00 + trk.tx.y * trk.tx.y * trk.W_11;
      const float zerr = 1.f / sqrtf(zweight);
      // get rid of useless tracks. must be a bit carefull with this.
      const float maxTrackZ0Err = trk.z < SMOG2_pp_separation ? SMOG2_maxTrackZ0Err : pp_maxTrackZ0Err;

      if (zerr < maxTrackZ0Err) { // m_nsigma < 10*m_dz ) {
        // find better place to define this
        const float a = sqrtf(float(2 * order_polynomial + 3));
        const float halfwindow = a * zerr / dz;
        // this looks a bit funny, but we need the first and last bin of the histogram to remain empty.
        const int minbin = max(int(zbin - halfwindow), 1);
        const int maxbin = min(int(zbin + halfwindow), Nbins - 2);
        // we can get rid of this if statement if we make a selection of seeds earlier
        if (maxbin >= minbin) {
          float integral = 0;
          for (auto i = minbin; i < maxbin; ++i) {
            const float relz = (zmin + (i + 1) * dz - trk.z) / zerr;
            const float thisintegral = gauss_integral(relz, order_polynomial);
            atomicAdd(histo_base_pointer + i, thisintegral - integral);
            integral = thisintegral;
          }
          // deal with the last bin
          atomicAdd(histo_base_pointer + maxbin, 1.f - integral);
        }
      }
    }
  }
}
