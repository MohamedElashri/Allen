/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "D2KsHHLine.cuh"
#include "VertexFitDeviceFunctions.cuh"

INSTANTIATE_LINE(d2kshh_line::d2kshh_line_t, d2kshh_line::Parameters)

// Get the invariant mass of a pair of vertices
__device__ float d2kshh_line::d2kshh_line_t::m(
  const Allen::Views::Physics::CompositeParticle* vertex1,
  const Allen::Views::Physics::CompositeParticle* vertex2,
  const float m1,
  const float m2)
{
  const auto v1 = vertex1->vertex();
  const auto v2 = vertex2->vertex();
  const float E1 = sqrtf(v1.px() * v1.px() + v1.py() * v1.py() + v1.pz() * v1.pz() + m1 * m1);
  const float E2 = sqrtf(v2.px() * v2.px() + v2.py() * v2.py() + v2.pz() * v2.pz() + m2 * m2);
  return sqrtf(m1 * m1 + m2 * m2 + 2.f * (E1 * E2 - (v1.px() * v2.px() + v1.py() * v2.py() + v1.pz() * v2.pz())));
}

// Get the absolute momentum of a pair of vertices
__device__ float d2kshh_line::d2kshh_line_t::p(
  const Allen::Views::Physics::CompositeParticle* vertex1,
  const Allen::Views::Physics::CompositeParticle* vertex2)
{
  const auto v1 = vertex1->vertex();
  const auto v2 = vertex2->vertex();
  return sqrtf(
    (v1.px() + v2.px()) * (v1.px() + v2.px()) + (v1.py() + v2.py()) * (v1.py() + v2.py()) +
    (v1.pz() + v2.pz()) * (v1.pz() + v2.pz()));
}

// Get the transverse momentum of a pair of vertices
__device__ float d2kshh_line::d2kshh_line_t::pt(
  const Allen::Views::Physics::CompositeParticle* vertex1,
  const Allen::Views::Physics::CompositeParticle* vertex2)
{
  const auto v1 = vertex1->vertex();
  const auto v2 = vertex2->vertex();
  return sqrtf((v1.px() + v2.px()) * (v1.px() + v2.px()) + (v1.py() + v2.py()) * (v1.py() + v2.py()));
}

// Get the lifetime of a pair of vertices
__device__ float d2kshh_line::d2kshh_line_t::ctau(
  const Allen::Views::Physics::CompositeParticle* vertex1,
  const Allen::Views::Physics::CompositeParticle* vertex2)
{
  // This function calculates lifetime as ctau = m*L/p (mm)
  const auto v1 = vertex1->vertex();
  const auto v2 = vertex2->vertex();
  auto L =
    (v1.z() > v2.z()) ? vertex2->fd() : vertex1->fd(); // take v2 as D0 vtx position if v1 downstream and vice-versa
  auto M = m(vertex1, vertex2, vertex1->m(), vertex2->m()); // m(4pi) hypothesis (lowest mass among the 4)
  auto P = p(vertex1, vertex2);
  return M * L / P;
}

// Invariant mass of a vertex candidate and a basic particle
__device__ float d2kshh_line::d2kshh_line_t::mSq(
  const Allen::Views::Physics::CompositeParticle* vertex,
  const Allen::Views::Physics::BasicParticle* particle,
  const float m1,
  const float m2)
{
  const auto ks = vertex->vertex();
  const auto hh = particle->state();
  const float E1 = sqrtf(ks.px() * ks.px() + ks.py() * ks.py() + ks.pz() * ks.pz() + m1 * m1);
  const float E2 = sqrtf(hh.px() * hh.px() + hh.py() * hh.py() + hh.pz() * hh.pz() + m2 * m2);
  return m1 * m1 + m2 * m2 + 2.f * (E1 * E2 - (ks.px() * hh.px() + ks.py() * hh.py() + ks.pz() * hh.pz()));
}

// Selection function
__device__ bool d2kshh_line::d2kshh_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  // Unpack the tuple.
  const auto sv = std::get<0>(input);
  const auto ks = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(0));
  const auto hh = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(1));

  // Check the V-particles are neutral
  bool opposite_sign = (ks->charge() == 0 && hh->charge() == 0);
  if (!opposite_sign) return false;

  // DOCA between vertices
  bool comb_cuts = Allen::Views::Physics::state_doca(ks->get_state(), hh->get_state()) < properties.maxDOCA;
  if (!comb_cuts) return false;

  // Vertex quality cuts.
  comb_cuts &= ks->vertex().chi2() >= 0 && ks->vertex().chi2() < properties.maxVertexChi2 && hh->vertex().chi2() > 0 &&
               hh->vertex().chi2() < properties.maxVertexChi2;
  if (!comb_cuts) return false;

  // D0 proper time cut
  comb_cuts &= ctau(ks, hh) > properties.minCTau_D0; // all pions
  // D0 minimum pt
  comb_cuts &= pt(ks, hh) > properties.minComboPt_D0; // all pions
  if (!comb_cuts) return false;

  // Invariant mass cut
  auto mks = ks->m();                                                            // m(ks,Allen::mPi, Allen::mPi);
  auto mpipi = hh->m();                                                          // m(hh,Allen::mPi, Allen::mPi);
  comb_cuts = fabsf(m(ks, hh, mks, mpipi) - Allen::mDz) < properties.massWindow; // all pions

  bool ks_cuts = true;
  // require the KS to be downstream of the D0
  if (ks->vertex().z() < hh->vertex().z()) return false;
  ks_cuts &= (ks->vertex().z() > hh->vertex().z());
  // KS Mass cuts.
  ks_cuts &= ks->mdipi() > properties.minM_Ks;
  ks_cuts &= ks->mdipi() < properties.maxM_Ks;
  if (!ks_cuts) return false;

  // KS PT
  ks_cuts &= ks->vertex().pt() > properties.minComboPt_Ks;
  if (!ks_cuts) return false;

  // D0 Invariant mass
  auto mkpi = hh->m12(Allen::mK, Allen::mPi); // Kpi
  comb_cuts |= fabsf(m(ks, hh, mks, mkpi) - Allen::mDz) < properties.massWindow;
  auto mpik = hh->m12(Allen::mPi, Allen::mK); // piK
  comb_cuts |= fabsf(m(ks, hh, mks, mpik) - Allen::mDz) < properties.massWindow;
  auto mkk = hh->m12(Allen::mK, Allen::mK); // KK
  comb_cuts |= fabsf(m(ks, hh, mks, mkk) - Allen::mDz) < properties.massWindow;
  if (!comb_cuts) return false;

  // KS selection
  // Kinematic cuts
  ks_cuts &= ks->minpt() > properties.minTrackPt_Ks;
  ks_cuts &= ks->minp() > properties.minTrackP_Ks;
  ks_cuts &= ks->eta() > properties.minEta_Ks;
  ks_cuts &= ks->eta() < properties.maxEta_Ks;
  ks_cuts &= ks->minip() > properties.minTrackIP_Ks;
  if (!ks_cuts) return false;

  // hh selection
  // Kinematic cuts
  bool hh_cuts = true;
  hh_cuts &= hh->doca12() < properties.maxDOCA_hh;
  hh_cuts &= hh->minpt() > properties.minTrackPt_hh;
  hh_cuts &= hh->minp() > properties.minTrackP_hh;
  hh_cuts &= hh->minip() > properties.minTrackIP_hh;
  hh_cuts &= hh->eta() < properties.maxEta_hh;
  hh_cuts &= hh->eta() > properties.minEta_hh;

  return comb_cuts && ks_cuts && hh_cuts;
}

__device__ void d2kshh_line::d2kshh_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto sv = std::get<0>(input);
    const auto ks = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(0));
    const auto hh = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(1));
    // Fill histograms
    properties.histogram_d02kshh_mass.increment(m(ks, hh, Allen::mPi, Allen::mPi));
    properties.histogram_d02kshh_pt.increment(pt(ks, hh));
    properties.histogram_d02kshh_ctau.increment(ctau(ks, hh));
    properties.histogram_d02kshh_mKS.increment(ks->m());
    properties.histogram_d02kshh_mhh.increment(hh->m());
  }
}

__device__ bool d2kshh_line::d2kshh_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto sv = std::get<0>(input);
    const auto ks = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(0));
    const auto hh = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(1));
    const auto ks_1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks->child(0));
    const auto ks_2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks->child(1));
    const auto hh_1 = static_cast<const Allen::Views::Physics::BasicParticle*>(hh->child(0));
    const auto hh_2 = static_cast<const Allen::Views::Physics::BasicParticle*>(hh->child(1));

    parameters.sv_masses[index] = m(ks, hh, Allen::mPi, Allen::mPi);
    parameters.pt[index] = pt(ks, hh);
    parameters.p[index] = p(ks, hh);
    parameters.doca[index] = Allen::Views::Physics::state_doca(ks->get_state(), hh->get_state());
    parameters.ctau[index] = ctau(ks, hh);
    const float m1 = ks->m();
    const float m2 = hh->m();
    if (ks->vertex().z() > hh->vertex().z()) {
      parameters.v1_m[index] = m1;
      parameters.v2_m[index] = m2;
      parameters.v1_minipchi2[index] = ks->minipchi2();
      parameters.v2_minipchi2[index] = hh->minipchi2();
      parameters.v1_minip[index] = ks->minip();
      parameters.v2_minip[index] = hh->minip();
      if (hh_1->state().charge() > 0) {
        parameters.msqp[index] = mSq(ks, hh_1, m1, Allen::mPi);
        parameters.msqm[index] = mSq(ks, hh_2, m1, Allen::mPi);
      }
      else {
        parameters.msqp[index] = mSq(ks, hh_2, m1, Allen::mPi);
        parameters.msqm[index] = mSq(ks, hh_1, m1, Allen::mPi);
      }
    }
    else {
      parameters.v1_m[index] = m2;
      parameters.v2_m[index] = m1;
      parameters.v1_minipchi2[index] = hh->minipchi2();
      parameters.v2_minipchi2[index] = ks->minipchi2();
      parameters.v1_minip[index] = hh->minip();
      parameters.v2_minip[index] = ks->minip();
      if (ks_1->state().charge() > 0) {
        parameters.msqp[index] = mSq(hh, ks_1, m1, Allen::mPi);
        parameters.msqm[index] = mSq(hh, ks_2, m1, Allen::mPi);
      }
      else {
        parameters.msqp[index] = mSq(hh, ks_2, m1, Allen::mPi);
        parameters.msqm[index] = mSq(hh, ks_1, m1, Allen::mPi);
      }
    }
  }
  return sel;
}