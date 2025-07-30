/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_JpsiToMuMuTaPLine.cuh"

INSTANTIATE_LINE(SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t, SMOG2jpsitomumu_tap_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>
SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_tracks = static_cast<const Allen::Views::Physics::CompositeParticles&>(
    parameters.dev_particle_container[0].container(event_number));
  const auto particle = event_tracks.particle(i);
  return std::forward_as_tuple(particle, event_number);
}

__device__ bool SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto jpsi = std::get<0>(input);
  if (jpsi.vertex().chi2() < 0) {
    return false;
  }
  const auto event_number = std::get<1>(input);
  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(1));

  const auto chi2corr_1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const auto chi2corr_2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk2->get_index()];

  const auto nn_1 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const auto nn_2 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk2->get_index()];

  if (jpsi.mdimu() < properties.JpsiMinMass || jpsi.mdimu() > properties.JpsiMaxMass) return false;
  if (jpsi.charge() != 0) return false;

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(1));

  const auto mutag = properties.posTag ? (track1->state().charge() > 0 ? track1 : track2) :
                                         (track1->state().charge() > 0 ? track2 : track1);
  const auto muprobe = properties.posTag ? (track1->state().charge() > 0 ? track2 : track1) :
                                           (track1->state().charge() > 0 ? track1 : track2);

  const auto chi2corr_tag = properties.posTag ? (track1->state().charge() > 0 ? chi2corr_1 : chi2corr_2) :
                                                (track1->state().charge() > 0 ? chi2corr_2 : chi2corr_1);

  const auto nn_tag =
    properties.posTag ? (track1->state().charge() > 0 ? nn_1 : nn_2) : (track1->state().charge() > 0 ? nn_2 : nn_1);
  bool muonid_bool = false;

  if (properties.useNN) {
    muonid_bool = nn_tag > properties.minMuonNN;
  }
  else {
    muonid_bool = chi2corr_tag < properties.mutagMaxChi2Corr;
  }
  bool decision =
    jpsi.vertex().chi2() < properties.JpsiMaxVChi2 && muonid_bool && jpsi.vertex().pt() > properties.JpsiMinPt &&
    jpsi.vertex().z() < properties.JpsiMaxZ && jpsi.vertex().z() >= properties.JpsiMinZ && jpsi.has_pv() &&
    jpsi.pv().position.z < properties.JpsiMaxZ && jpsi.pv().position.z >= properties.JpsiMinZ &&
    jpsi.doca12() < properties.JpsiMaxDoca && mutag->chi2() / mutag->ndof() < properties.maxTrackChi2Ndf &&
    muprobe->chi2() / muprobe->ndof() < properties.maxTrackChi2Ndf && mutag->is_muon() &&
    mutag->state().p() > properties.mutagMinP && mutag->state().pt() > properties.mutagMinPt &&
    muprobe->state().pt() > properties.muprobeMinPt && muprobe->state().p() > properties.muprobeMinP;
  return decision;
}

// monitoring
__device__ void SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
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
__device__ bool SMOG2jpsitomumu_tap_line::SMOG2jpsitomumu_tap_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto dimuon = std::get<0>(input);

    const auto event_number = std::get<1>(input);
    const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(dimuon.child(0));
    const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(dimuon.child(1));

    const auto chi2corr_1 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk1->get_index()];
    const auto chi2corr_2 = parameters.dev_chi2muon[parameters.dev_track_offsets[event_number] + trk2->get_index()];

    const auto nn_1 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk1->get_index()];
    const auto nn_2 = parameters.dev_muonidnn[parameters.dev_track_offsets[event_number] + trk2->get_index()];

    parameters.mass[index] = dimuon.mdimu();
    parameters.svz[index] = dimuon.vertex().z();
    parameters.pvz[index] = dimuon.pv().position.z;
    parameters.pt[index] = dimuon.vertex().pt();
    parameters.maxchi2corr[index] = max(chi2corr_1, chi2corr_2);
    parameters.min_muon_nn[index] = min(nn_1, nn_2);
  }
  return sel;
}
