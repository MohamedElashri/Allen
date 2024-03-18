/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DetJPsiToMuMuTaPLine.cuh"

INSTANTIATE_LINE(det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t, det_jpsitomumu_tap_line::Parameters)

void det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_det_jpsitomumu_tap_mass = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "histogram_det_jpsitomumu_tap_mass",
     "m(jpsi)",
     {property<histogram_mass_nbins_t>(), property<histogram_mass_min_t>(), property<histogram_mass_max_t>()}},
    {}};
#endif
}

void det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_mass_t>(arguments, property<histogram_mass_nbins_t>());
}

__device__ bool det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto jpsi = std::get<0>(input);

  if (jpsi.fdchi2() < parameters.JpsiMinFDChi2) return false;
  if (jpsi.mdimu() < parameters.JpsiMinMass || jpsi.mdimu() > parameters.JpsiMaxMass) return false;
  if (jpsi.charge() != 0) return false;

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(1));

  const auto mutag = parameters.posTag ? (track1->state().charge() > 0 ? track1 : track2) :
                                         (track1->state().charge() > 0 ? track2 : track1);
  const auto muprobe = parameters.posTag ? (track1->state().charge() > 0 ? track2 : track1) :
                                           (track1->state().charge() > 0 ? track1 : track2);

  bool decision = jpsi.vertex().chi2() > 0 && jpsi.vertex().chi2() < parameters.JpsiMaxVChi2 &&
                  jpsi.vertex().pt() > parameters.JpsiMinPt && jpsi.vertex().z() >= parameters.JpsiMinZ &&
                  jpsi.doca12() < parameters.JpsiMaxDoca && jpsi.dira() > parameters.JpsiMinCosDira &&
                  mutag->is_muon() && mutag->state().p() > parameters.mutagMinP &&
                  mutag->state().pt() > parameters.mutagMinPt && mutag->ip_chi2() > parameters.mutagMinIPChi2 &&
                  muprobe->ip_chi2() > parameters.muprobeMinIPChi2 && muprobe->state().p() > parameters.muprobeMinP;
  return decision;
}

// monitoring
void det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_mass_t>(arguments, 0, context);
}

__device__ void det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto jpsi = std::get<0>(input);
    const auto m = jpsi.mdimu();
    if (m > parameters.histogram_mass_min && m < parameters.histogram_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m - parameters.histogram_mass_min) * parameters.histogram_mass_nbins /
        (parameters.histogram_mass_max - parameters.histogram_mass_min));
      atomicAdd(&parameters.dev_histogram_mass[bin], 1);
    }
  }
}

void det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {get<dev_histogram_mass_t>(arguments),
                histogram_det_jpsitomumu_tap_mass,
                property<histogram_mass_min_t>(),
                property<histogram_mass_max_t>()});
#endif
}

__device__ void det_jpsitomumu_tap_line::det_jpsitomumu_tap_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  const auto jpsi = std::get<0>(input);

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(jpsi.child(1));

  const auto mutag = parameters.posTag ? (track1->state().charge() > 0 ? track1 : track2) :
                                         (track1->state().charge() > 0 ? track2 : track1);
  const auto muprobe = parameters.posTag ? (track1->state().charge() > 0 ? track2 : track1) :
                                           (track1->state().charge() > 0 ? track1 : track2);

  if (1) {

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
}