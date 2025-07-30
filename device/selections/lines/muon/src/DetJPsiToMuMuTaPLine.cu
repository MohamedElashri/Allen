/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DetJPsiToMuMuTaPLine.cuh"

INSTANTIATE_LINE(det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t, det_jpsitomumu_tap_line::Parameters)

__device__ bool det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto jpsi = std::get<0>(input);

  if (jpsi.fdchi2() < properties.JpsiMinFDChi2) return false;
  if (jpsi.mdimu() < properties.JpsiMinMass || jpsi.mdimu() > properties.JpsiMaxMass) return false;
  if (jpsi.charge() != 0) return false;

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(1));

  const auto mutag = properties.posTag ? (track1->state().charge() > 0 ? track1 : track2) :
                                         (track1->state().charge() > 0 ? track2 : track1);
  const auto muprobe = properties.posTag ? (track1->state().charge() > 0 ? track2 : track1) :
                                           (track1->state().charge() > 0 ? track1 : track2);

  bool decision = jpsi.vertex().chi2() > 0 && jpsi.vertex().chi2() < properties.JpsiMaxVChi2 &&
                  jpsi.vertex().pt() > properties.JpsiMinPt && jpsi.vertex().z() >= properties.JpsiMinZ &&
                  jpsi.doca12() < properties.JpsiMaxDoca && jpsi.dira() > properties.JpsiMinCosDira &&
                  mutag->is_muon() && mutag->state().p() > properties.mutagMinP &&
                  mutag->state().pt() > properties.mutagMinPt && mutag->ip_chi2() > properties.mutagMinIPChi2 &&
                  muprobe->ip_chi2() > properties.muprobeMinIPChi2 && muprobe->state().p() > properties.muprobeMinP;
  return decision;
}

// monitoring

__device__ void det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto jpsi = std::get<0>(input);
    const auto m = jpsi.mdimu();
    properties.histogram_det_jpsitomumu_tap_mass.increment(m);
  }
}

__device__ bool det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto jpsi = std::get<0>(input);

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(1));

  const auto mutag = properties.posTag ? (track1->state().charge() > 0 ? track1 : track2) :
                                         (track1->state().charge() > 0 ? track2 : track1);
  const auto muprobe = properties.posTag ? (track1->state().charge() > 0 ? track2 : track1) :
                                           (track1->state().charge() > 0 ? track1 : track2);

  if (sel) {
    parameters.decision[index] = sel;
    parameters.jpsi_mass[index] = jpsi.mdimu();
    parameters.jpsi_dira[index] = jpsi.dira();
    parameters.jpsi_doca[index] = jpsi.doca12();
    parameters.jpsi_vchi2[index] = jpsi.vertex().chi2();
    parameters.jpsi_minipchi2[index] = jpsi.minipchi2();
    parameters.jpsi_eta[index] = jpsi.eta();
    parameters.jpsi_vz[index] = jpsi.vertex().z();
    parameters.jpsi_minpt[index] = jpsi.minpt();
    parameters.jpsi_vdz[index] = jpsi.dz();
    parameters.jpsi_fd[index] = jpsi.fd();
    parameters.jpsi_p[index] = jpsi.vertex().p();
    parameters.jpsi_pz[index] = jpsi.vertex().pz();
    parameters.jpsi_pt[index] = jpsi.vertex().pt();
    parameters.jpsi_fdchi2[index] = jpsi.fdchi2();

    parameters.mutag_charge[index] = mutag->state().charge();
    parameters.muprobe_charge[index] = muprobe->state().charge();
    parameters.mutag_ismuon[index] = mutag->is_muon();
    parameters.muprobe_ismuon[index] = muprobe->is_muon();
    parameters.mutag_p[index] = mutag->state().p();
    parameters.muprobe_p[index] = muprobe->state().p();
    parameters.mutag_ipchi2[index] = mutag->ip_chi2();
    parameters.muprobe_ipchi2[index] = muprobe->ip_chi2();
    parameters.mutag_pt[index] = mutag->state().pt();
    parameters.muprobe_pt[index] = muprobe->state().pt();
    parameters.mutag_px[index] = mutag->state().px();
    parameters.muprobe_px[index] = muprobe->state().px();
    parameters.mutag_py[index] = mutag->state().py();
    parameters.muprobe_py[index] = muprobe->state().py();
    parameters.mutag_pz[index] = mutag->state().pz();
    parameters.muprobe_pz[index] = muprobe->state().pz();
    parameters.mutag_chi2ndof[index] = mutag->state().chi2() / mutag->state().ndof();
    parameters.muprobe_chi2ndof[index] = muprobe->state().chi2() / muprobe->state().ndof();
    parameters.mutag_eta[index] = mutag->state().eta();
    parameters.muprobe_eta[index] = muprobe->state().eta();
  }

  return sel;
}
