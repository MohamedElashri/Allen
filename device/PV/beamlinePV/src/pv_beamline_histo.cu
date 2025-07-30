
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
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_zhisto_t>(arguments, 0, context);

  global_function(pv_beamline_histo)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
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

void updateCommon(const Constants& constants)
{
  struct BeamlinePVConstants::Common::Beamline host_beamline;

  host_beamline.pos.x = constants.host_beamline[0];
  host_beamline.pos.y = constants.host_beamline[1];
  host_beamline.pos.z = constants.host_beamline[2];

  for (long unsigned int i = 0; i < 6; i++) { // spread matrix have 6 elements
    host_beamline.sprd[i] = constants.host_beamline[3 + i];
  }
  double beamlineTx = 0.;
  double beamlineTy = 0.; // Beamline inclination is set at zero for now. This will be modified later
  host_beamline.tx.x = beamlineTx;
  host_beamline.tx.y = beamlineTy;

  // To stay backward compatible we need to check the size of host_beamline. In version 0 and 1 of the beamline only
  // position with 3 elements and spread matrix with 6 were included
  double CrossingAngleh = constants.host_beamline.size() == 9 ?
                            0 :
                            static_cast<double>(constants.host_beamline[9]) /
                              (2 * std::pow(10, 6)); // Convert crossing angles between beams from microrad to rad,
                                                     // take half to convert the angle to the beam inclination
  if ((CrossingAngleh == 0.0) & (constants.host_gen_crossing_angles.size() == 2)) {
    CrossingAngleh = fabs(static_cast<double>(constants.host_gen_crossing_angles[0])) / 2;
  }
  double CrossingAnglev =
    constants.host_beamline.size() == 9 ? 0 : static_cast<double>(constants.host_beamline[10]) / (2 * std::pow(10, 6));

  if ((CrossingAnglev == 0.0) & (constants.host_gen_crossing_angles.size() == 2)) {
    CrossingAnglev = fabs(static_cast<double>(constants.host_gen_crossing_angles[1])) / 2;
  }
  host_beamline.tx_SMOG.x = beamlineTx + CrossingAngleh;
  host_beamline.tx_SMOG.y = beamlineTy + CrossingAnglev;
  Allen::memcpyToSymbol(dev_beamline, &host_beamline, sizeof(struct BeamlinePVConstants::Common::Beamline));
}

void pv_beamline_histo::pv_beamline_histo_t::update(const Constants& constants) const { updateCommon(constants); }

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
    float tx_beam;
    float ty_beam;
    if (trk.z > SMOG2_pp_separation) {
      tx_beam = dev_beamline.tx.x;
      ty_beam = dev_beamline.tx.y;
    }
    else {
      tx_beam = dev_beamline.tx_SMOG.x;
      ty_beam = dev_beamline.tx_SMOG.y;
    }
    if (zmin < trk.z && trk.z < zmax) {
      const float diffx2 =
        (trk.x.x - dev_beamline.pos.x - tx_beam * trk.z) * (trk.x.x - dev_beamline.pos.x - tx_beam * trk.z);
      const float diffy2 =
        (trk.x.y - dev_beamline.pos.y - ty_beam * trk.z) * (trk.x.y - dev_beamline.pos.y - ty_beam * trk.z);
      const float blchi2 = diffx2 * trk.W_00 + diffy2 * trk.W_11;
      if (blchi2 >= maxTrackBlChi2) continue;

      // bin in which z0 is, in floating point
      const float zbin = (trk.z - zmin) / dz;

      auto const tx = trk.tx.x - tx_beam;
      auto const ty = trk.tx.y - ty_beam;

      const float zweight = tx * tx * trk.W_00 + ty * ty * trk.W_11;
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
