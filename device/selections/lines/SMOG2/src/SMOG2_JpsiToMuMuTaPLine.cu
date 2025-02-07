/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_JpsiToMuMuTaPLine.cuh"

INSTANTIATE_LINE(SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t, SMOG2jpsitomumu_tap_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float, const float>
SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto particle = event_tracks.particle(i);
  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));
  const auto chi2corr_1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + track1->get_index()];
  const auto chi2corr_2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + track2->get_index()];

  return std::forward_as_tuple(particle, chi2corr_1, chi2corr_2);
}

__device__ bool SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float, const float> input)
{
  const auto jpsi = std::get<0>(input);
  if (jpsi.vertex().chi2() < 0) {
    return false;
  }
  const auto chi2corr_1 = std::get<1>(input);
  const auto chi2corr_2 = std::get<2>(input);

  if (jpsi.mdimu() < properties.JpsiMinMass || jpsi.mdimu() > properties.JpsiMaxMass) return false;
  if (jpsi.charge() != 0) return false;

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(1));

  const auto mutag = properties.posTag ? (track1->state().charge() > 0 ? track1 : track2) :
                                         (track1->state().charge() > 0 ? track2 : track1);
  const auto chi2corr_tag = properties.posTag ? (track1->state().charge() > 0 ? chi2corr_1 : chi2corr_2) :
                                                (track1->state().charge() > 0 ? chi2corr_2 : chi2corr_1);
  const auto muprobe = properties.posTag ? (track1->state().charge() > 0 ? track2 : track1) :
                                           (track1->state().charge() > 0 ? track1 : track2);

  bool decision = jpsi.vertex().chi2() < properties.JpsiMaxVChi2 && chi2corr_tag < properties.mutagMaxChi2Corr &&
                  jpsi.vertex().pt() > properties.JpsiMinPt && jpsi.vertex().z() < properties.JpsiMaxZ &&
                  jpsi.vertex().z() >= properties.JpsiMinZ && jpsi.has_pv() &&
                  jpsi.pv().position.z < properties.JpsiMaxZ && jpsi.pv().position.z >= properties.JpsiMinZ &&
                  jpsi.doca12() < properties.JpsiMaxDoca &&
                  mutag->chi2() / mutag->ndof() < properties.maxTrackChi2Ndf &&
                  muprobe->chi2() / muprobe->ndof() < properties.maxTrackChi2Ndf && mutag->is_muon() &&
                  mutag->state().p() > properties.mutagMinP && mutag->state().pt() > properties.mutagMinPt &&
                  muprobe->state().pt() > properties.muprobeMinPt && muprobe->state().p() > properties.muprobeMinP;
  return decision;
}

// monitoring
__device__ void SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float, const float> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto jpsi = std::get<0>(input);
    const auto m = jpsi.mdimu();
    properties.histogram_SMOG2jpsitomumu_tap_mass.increment(m);
  }
}

// tupling
__device__ void SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const float, const float> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto dimuon = std::get<0>(input);

    parameters.mass[index] = dimuon.mdimu();
    parameters.svz[index] = dimuon.vertex().z();
    parameters.pvz[index] = dimuon.pv().position.z;
    parameters.pt[index] = dimuon.vertex().pt();
    parameters.maxchi2corr[index] = std::get<1>(input);
  }
}
