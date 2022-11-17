/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TwoTrackMVACharmXSec.cuh"

INSTANTIATE_LINE(
  two_track_mva_charm_xsec_line::two_track_mva_charm_xsec_line_t,
  two_track_mva_charm_xsec_line::Parameters)

namespace two_track_mva_charm_xsec_line {

  __device__ std::tuple<const CompositeParticle, const float> two_track_mva_charm_xsec_line_t::get_input(
    const Parameters& parameters,
    const unsigned event_number,
    const unsigned i)
  {
    const auto particles = static_cast<const Allen::Views::Physics::CompositeParticles>(
      parameters.dev_particle_container[0].container(event_number));
    const unsigned sv_index = i + particles.offset();
    const auto particle = particles.particle(i);
    return std::forward_as_tuple(particle, parameters.dev_two_track_mva_evaluation[sv_index]);
  }

  __device__ bool two_track_mva_charm_xsec_line_t::select(
    const Parameters& parameters,
    std::tuple<const CompositeParticle, const float> input)
  {
    const auto particle = std::get<0>(input);
    const auto response = std::get<1>(input);
    const auto vertex = particle.vertex();
    if (vertex.chi2() < 0) {
      return false;
    }

    /**
     * We target D0->Kpi, D0->Kpipipi, D+->Kpipi, D+->KKpi, Ds+->KKpi, Lbc+->pKpi, Xic->pKpi, Xic0->pKKpi.
     * Therefore, a two track combination can be checked to have an invariant mass around the D0 mass OR
     * be less than `maxCombKpiMass` which is set such that it selects all the modes that are missing a
     * particle or two.
     */
    auto massDecision = [&particle, &parameters] {
      const auto m1 = particle.m12(Allen::mK, Allen::mPi);
      const auto m2 = particle.m12(Allen::mPi, Allen::mK);
      const auto dzero = min(fabsf(m1 - Allen::mDz), fabsf(m2 - Allen::mDz)) < parameters.massWindow;
      const auto other = min(m1, m2) < parameters.maxCombKpiMass;
      return dzero || other;
    };

    const auto preselection = vertex.chi2() < parameters.maxVertexChi2 && particle.minpt() > parameters.minTrackPt &&
                              particle.minp() > parameters.minTrackP && particle.docamax() < parameters.maxDOCA &&
                              massDecision() && particle.minipchi2() > parameters.minTrackIPChi2 &&
                              vertex.z() >= parameters.minZ && particle.pv().position.z >= parameters.minZ;

    /*
     * After a rough selection of genereall intersting tracks and vertices two different MVA response cuts
     * are applied, one for low transverse momentum two-track candidates and one for high transverse momentum ones.
     * This is because the default cut (0.92385) removes all (as far as I can tell from limited MC statistics) low
     * transverse momentum candidates (PT < 1 GeV), but performs well for PT > 1.5 GeV. The cut for low PT is loosenend
     * such that candidates with PT < 1 GeV pass.
     */
    const auto low_pt_selection = preselection && vertex.pt() < parameters.lowSVpt && response > parameters.minMVAlowPt;
    const auto high_pt_selection =
      preselection && vertex.pt() >= parameters.lowSVpt && response > parameters.minMVAhighPt;

    return low_pt_selection || high_pt_selection;
  }
} // namespace two_track_mva_charm_xsec_line
