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
  const auto p1 = vertex->vertex();
  const auto p2 = particle->state();
  const float E1 = sqrtf(p1.px() * p1.px() + p1.py() * p1.py() + p1.pz() * p1.pz() + m1 * m1);
  const float E2 = sqrtf(p2.px() * p2.px() + p2.py() * p2.py() + p2.pz() * p2.pz() + m2 * m2);
  return m1 * m1 + m2 * m2 + 2.f * (E1 * E2 - (p1.px() * p2.px() + p1.py() * p2.py() + p1.pz() * p2.pz()));
}

// Selection function
__device__ bool d2kshh_line::d2kshh_line_t::select(
  const Parameters& parameters,
  const DeviceAccumulators&,
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
  bool comb_cuts = Allen::Views::Physics::state_doca(ks->get_state(), hh->get_state()) < parameters.maxDOCA;
  if (!comb_cuts) return false;

  // Vertex quality cuts.
  comb_cuts &= ks->vertex().chi2() > 0 && ks->vertex().chi2() < parameters.maxVertexChi2 && hh->vertex().chi2() > 0 &&
               hh->vertex().chi2() < parameters.maxVertexChi2;
  if (!comb_cuts) return false;

  // D0 proper time cut
  comb_cuts &= ctau(ks, hh) > parameters.minCTau_D0; // all pions
  // D0 minimum pt
  comb_cuts &= pt(ks, hh) > parameters.minComboPt_D0; // all pions
  if (!comb_cuts) return false;

  // Invariant mass cut
  auto mks = ks->m();                                                            // m(p1,Allen::mPi, Allen::mPi);
  auto mpipi = hh->m();                                                          // m(p2,Allen::mPi, Allen::mPi);
  comb_cuts = fabsf(m(ks, hh, mks, mpipi) - Allen::mDz) < parameters.massWindow; // all pions

  bool ks_cuts = true;
  // require the KS to be downstream of the D0
  if (ks->vertex().z() < hh->vertex().z()) return false;
  ks_cuts &= (ks->vertex().z() > hh->vertex().z());
  // KS Mass cuts.
  ks_cuts &= ks->mdipi() > parameters.minM_Ks;
  ks_cuts &= ks->mdipi() < parameters.maxM_Ks;
  if (!ks_cuts) return false;

  // KS PT
  ks_cuts &= ks->vertex().pt() > parameters.minComboPt_Ks;
  if (!ks_cuts) return false;

  // D0 Invariant mass
  auto mkpi = hh->m12(Allen::mK, Allen::mPi); // Kpi
  comb_cuts |= fabsf(m(ks, hh, mks, mkpi) - Allen::mDz) < parameters.massWindow;
  auto mpik = hh->m12(Allen::mPi, Allen::mK); // piK
  comb_cuts |= fabsf(m(ks, hh, mks, mpik) - Allen::mDz) < parameters.massWindow;
  auto mkk = hh->m12(Allen::mK, Allen::mK); // KK
  comb_cuts |= fabsf(m(ks, hh, mks, mkk) - Allen::mDz) < parameters.massWindow;
  if (!comb_cuts) return false;

  // KS selection
  // Kinematic cuts
  ks_cuts &= ks->minpt() > parameters.minTrackPt_Ks;
  ks_cuts &= ks->minp() > parameters.minTrackP_Ks;
  ks_cuts &= ks->eta() > parameters.minEta_Ks;
  ks_cuts &= ks->eta() < parameters.maxEta_Ks;
  ks_cuts &= ks->minip() > parameters.minTrackIP_Ks;
  if (!ks_cuts) return false;

  // hh selection
  // Kinematic cuts
  bool hh_cuts = true;
  hh_cuts &= hh->doca12() < parameters.maxDOCA_hh;
  hh_cuts &= hh->minpt() > parameters.minTrackPt_hh;
  hh_cuts &= hh->minp() > parameters.minTrackP_hh;
  hh_cuts &= hh->minip() > parameters.minTrackIP_hh;
  hh_cuts &= hh->eta() < parameters.maxEta_hh;
  hh_cuts &= hh->eta() > parameters.minEta_hh;

  return comb_cuts && ks_cuts && hh_cuts;
}

__device__ void d2kshh_line::d2kshh_line_t::monitor(
  const Parameters&,
  const DeviceAccumulators& accumulators,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto sv = std::get<0>(input);
    const auto ks = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(0));
    const auto hh = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(1));
    // Fill histograms
    accumulators.histogram_d02kshh_mass.increment(m(ks, hh, Allen::mPi, Allen::mPi));
    accumulators.histogram_d02kshh_pt.increment(pt(ks, hh));
    accumulators.histogram_d02kshh_ctau.increment(ctau(ks, hh));
    accumulators.histogram_d02kshh_mKS.increment(ks->m());
    accumulators.histogram_d02kshh_mhh.increment(hh->m());
  }
}

__device__ void d2kshh_line::d2kshh_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto sv = std::get<0>(input);
    const auto p1 = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(0));
    const auto p2 = static_cast<const Allen::Views::Physics::CompositeParticle*>(sv.child(1));
    const auto p1_1 = static_cast<const Allen::Views::Physics::BasicParticle*>(p1->child(0));
    const auto p1_2 = static_cast<const Allen::Views::Physics::BasicParticle*>(p1->child(1));
    const auto p2_1 = static_cast<const Allen::Views::Physics::BasicParticle*>(p2->child(0));
    const auto p2_2 = static_cast<const Allen::Views::Physics::BasicParticle*>(p2->child(1));

    parameters.sv_masses[index] = m(p1, p2, Allen::mPi, Allen::mPi);
    parameters.pt[index] = pt(p1, p2);
    parameters.p[index] = p(p1, p2);
    parameters.doca[index] = Allen::Views::Physics::state_doca(p1->get_state(), p2->get_state());
    parameters.ctau[index] = ctau(p1, p2);
    const float m1 = p1->m();
    const float m2 = p2->m();
    if (p1->vertex().z() > p2->vertex().z()) {
      parameters.v1_m[index] = m1;
      parameters.v2_m[index] = m2;
      parameters.v1_minipchi2[index] = p1->minipchi2();
      parameters.v2_minipchi2[index] = p2->minipchi2();
      parameters.v1_minip[index] = p1->minip();
      parameters.v2_minip[index] = p2->minip();
      if (p2_1->state().charge() > 0) {
        parameters.msqp[index] = mSq(p1, p2_1, m1, Allen::mPi);
        parameters.msqm[index] = mSq(p1, p2_2, m1, Allen::mPi);
      }
      else {
        parameters.msqp[index] = mSq(p1, p2_2, m1, Allen::mPi);
        parameters.msqm[index] = mSq(p1, p2_1, m1, Allen::mPi);
      }
    }
    else {
      parameters.v1_m[index] = m2;
      parameters.v2_m[index] = m1;
      parameters.v1_minipchi2[index] = p2->minipchi2();
      parameters.v2_minipchi2[index] = p1->minipchi2();
      parameters.v1_minip[index] = p2->minip();
      parameters.v2_minip[index] = p1->minip();
      if (p1_1->state().charge() > 0) {
        parameters.msqp[index] = mSq(p2, p1_1, m1, Allen::mPi);
        parameters.msqm[index] = mSq(p2, p1_2, m1, Allen::mPi);
      }
      else {
        parameters.msqp[index] = mSq(p2, p1_2, m1, Allen::mPi);
        parameters.msqm[index] = mSq(p2, p1_1, m1, Allen::mPi);
      }
    }
  }
}