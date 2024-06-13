/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DownstreamVertexing.cuh"

INSTANTIATE_ALGORITHM(downstream_vertexing::downstream_vertexing_t)

void downstream_vertexing::downstream_vertexing_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_downstream_secondary_vertices_t>(
    arguments, first<host_number_of_events_t>(arguments) * VertexFit::max_svs);
  set_size<dev_offsets_downstream_secondary_vertices_t>(arguments, first<host_number_of_events_t>(arguments));
}

void downstream_vertexing::downstream_vertexing_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_downstream_secondary_vertices_t>(arguments, 0, context);
  Allen::memset_async<dev_offsets_downstream_secondary_vertices_t>(arguments, 0, context);

  global_function(downstream_vertexing)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_magnet_polarity.data(), constants.dev_downstream_composite_quality_evaluator);
}

namespace {

  template<unsigned MaxIter>
  __device__ inline float compute_dz_from_poca(
    const float xA,
    const float txA,
    const float gA,
    const float yA,
    const float tyA,
    const float xB,
    const float txB,
    const float gB,
    const float yB,
    const float tyB,
    const float dz0)
  {
    const auto a = txA * xA - txB * xA - txA * xB + txB * xB + tyA * yA - tyB * yA - tyA * yB + tyB * yB;
    const auto b = txA * txA - 2 * txA * txB + txB * txB + tyA * tyA - 2 * tyA * tyB + tyB * tyB + 2 * gA * xA -
                   2 * gB * xA - 2 * gA * xB + 2 * gB * xB;
    const auto c = 3 * gA * txA - 3 * gB * txA - 3 * gA * txB + 3 * gB * txB;
    const auto d = 2 * gA * gA - 4 * gA * gB + 2 * gB * gB;

    auto f = [a, b, c, d](const float z) { return a + b * z + c * z * z + d * z * z * z; };
    auto fp = [b, c, d](const float z) { return b + 2 * c * z + 3 * d * z * z; };

    const auto dz = Downstream::DownstreamHelpers::find_root<MaxIter>(f, fp, dz0);

    return dz;
  }

  struct vertexing_fit_result_t {
    float x, y, z, dx2, dy2;
    float Atx, Btx;
  };
  template<unsigned MaxIter>
  __device__ inline vertexing_fit_result_t vertexing(
    const float xA,
    const float txA,
    const float yA,
    const float tyA,
    const float qopA,
    const float xB,
    const float txB,
    const float yB,
    const float tyB,
    const float qopB,
    const float polarity)
  {
    vertexing_fit_result_t result;

    // Initial estimation of g
    const auto gA = Downstream::DownstreamExtrapolation::Physics::gamma(qopA, polarity);
    const auto gB = Downstream::DownstreamExtrapolation::Physics::gamma(qopB, polarity);

    // Initial estimation of dz
    const auto dz0 = ((-txA) * xA + txB * xA + txA * xB - txB * xB - tyA * yA + tyB * yA + tyA * yB - tyB * yB) /
                     (txA * txA - 2 * txA * txB + txB * txB + tyA * tyA - 2 * tyA * tyB + tyB * tyB);

    // Find poca
    const auto dz = compute_dz_from_poca<MaxIter>(xA, txA, gA, yA, tyA, xB, txB, gB, yB, tyB, dz0);

    // Estimate new expected vtx position
    const auto vA_x = xA + txA * dz + gA * dz * dz;
    const auto vB_x = xB + txB * dz + gB * dz * dz;
    const auto vA_y = yA + tyA * dz;
    const auto vB_y = yB + tyB * dz;

    // Fill output
    result.x = (vA_x + vB_x) / 2;
    result.y = (vA_y + vB_y) / 2;
    result.z = UT::Constants::zMidUT + dz;
    result.dx2 = (vA_x - vB_x) * (vA_x - vB_x);
    result.dy2 = (vA_y - vB_y) * (vA_y - vB_y);
    result.Atx = txA + 2 * gA * dz;
    result.Btx = txB + 2 * gB * dz;

    return result;
  }
} // namespace

__global__ void downstream_vertexing::downstream_vertexing(
  downstream_vertexing::Parameters parameters,
  const float* dev_magnet_polarity,
  const Allen::NeuralNetwork::Model::DownstreaCompositeQuality* dev_downstream_composite_quality_evaluator)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Fetch downstream tracks
  const auto downstream_particles = parameters.dev_multi_event_downstream_track_particles_view->container(event_number);
  const auto num_downstream_particles = downstream_particles.size();

  // Output
  auto num_downstream_secondary_vertices = parameters.dev_offsets_downstream_secondary_vertices + event_number;
  auto downstream_secondary_vertices = parameters.dev_downstream_secondary_vertices + event_number * VertexFit::max_svs;

  // Select particles
  __shared__ uint8_t particle_selection[UT::Constants::max_num_tracks];
  const auto tid = threadIdx.y * blockDim.x + threadIdx.x;
  const auto bdim = blockDim.x * blockDim.y;
  for (unsigned i = tid; i < num_downstream_particles; i += bdim) {
    const auto& downstream_particle = *downstream_particles.particle_pointer(i);
    const auto selection = (downstream_particle.state().pt() > parameters.track_min_pt_both.get()) &&
                           (downstream_particle.ownpv_ip() > parameters.track_min_ip_both.get()) &&
                           (parameters.dihadron && !downstream_particle.is_lepton());

    particle_selection[i] = !selection ? 0 : downstream_particle.state().charge() > 0 ? 1 : 2;
  }
  __syncthreads();

  // Select combinations
  for (unsigned daughterA_idx = threadIdx.x; daughterA_idx < num_downstream_particles; daughterA_idx += blockDim.x) {
    for (unsigned daughterB_idx = threadIdx.y + daughterA_idx + 1; daughterB_idx < num_downstream_particles;
         daughterB_idx += blockDim.y) {
      // Check if daughters are selected
      const auto Asel = particle_selection[daughterA_idx];
      const auto Bsel = particle_selection[daughterB_idx];
      const auto daughters_are_selected = (Asel + Bsel) == 3;
      if (!daughters_are_selected) continue;

      // Fetch elements
      const auto& daughterA = downstream_particles.particle(daughterA_idx);
      const auto& daughterB = downstream_particles.particle(daughterB_idx);

      const auto Apt = daughterA.state().pt();
      const auto Bpt = daughterB.state().pt();
      // const auto min_pt = Apt > Bpt ? Bpt : Apt;
      const auto max_pt = Apt > Bpt ? Apt : Bpt;

      const auto Aip = daughterA.ownpv_ip();
      const auto Bip = daughterB.ownpv_ip();
      // const auto min_ip = Aip > Bip ? Bip : Aip;
      const auto max_ip = Aip > Bip ? Aip : Bip;

      // Selection on combination
      const auto selection = (max_ip > parameters.track_min_ip_either) && (max_pt > parameters.track_min_ip_either) &&
                             ((Apt + Bpt) > parameters.sum_pt_min.get());
      if (!selection) continue;

      // Fit sv
      const auto sA = daughterA.state();
      const auto sB = daughterB.state();
      const auto vtx = vertexing<5>(
        sA.x(), sA.tx(), sA.y(), sA.ty(), sA.qop(), sB.x(), sB.tx(), sB.y(), sB.ty(), sB.qop(), *dev_magnet_polarity);

      // Recompute doca
      const auto doca = sqrtf(vtx.dx2 + vtx.dy2);

      // Filter divergent composites
      const auto vertex_selection = (doca < parameters.doca_max.get()) && (doca > 0) &&
                                    (vtx.z > parameters.min_vtx_z.get()) && (vtx.z < parameters.max_vtx_z.get());
      if (!vertex_selection) continue;

      // Compute the momentum
      const auto pA = sA.p();
      const auto pB = sB.p();

      const auto normA = sqrtf(1.f + vtx.Atx * vtx.Atx + sA.ty() * sA.ty());
      const auto normB = sqrtf(1.f + vtx.Btx * vtx.Btx + sB.ty() * sB.ty());

      const auto pAx = pA * vtx.Atx / normA;
      const auto pAy = pA * sA.ty() / normA;
      const auto pAz = pA / normA;
      const auto pBx = pB * vtx.Btx / normB;
      const auto pBy = pB * sB.ty() / normB;
      const auto pBz = pB / normB;

      const auto px = pAx + pBx;
      const auto py = pAy + pBy;
      const auto pz = pAz + pBz;

      // const auto pt = hypotf(px, py);

      // const auto eta = asinhf(pz / hypotf(px, py));

      // Make the composite quality and filter very bad quality composites
      float inputs[Allen::NeuralNetwork::Model::DownstreaCompositeQuality::nInput] {
        vtx.x, vtx.y, vtx.z, px / pz, py / pz, doca};
      const auto quality_score = Allen::NeuralNetwork::evaluate(dev_downstream_composite_quality_evaluator, inputs);
      if (quality_score < parameters.min_quality.get()) continue;

      // Compute Armenteros Podolansky plot for monitoring
      const auto p = sqrtf(px * px + py * py + pz * pz);
      const auto dA_rel_Pl = (pAx * px + pAy * py + pAz * pz) / p;
      const auto dB_rel_Pl = (pBx * px + pBy * py + pBz * pz) / p;
      const auto dA_rel_PT_x = pAy * pz - pAz * py;
      const auto dA_rel_PT_y = pAz * px - pAx * pz;
      const auto dA_rel_PT_z = pAx * py - pAy * px;
      const auto dA_rel_PT =
        sqrtf(dA_rel_PT_x * dA_rel_PT_x + dA_rel_PT_y * dA_rel_PT_y + dA_rel_PT_z * dA_rel_PT_z) / p;
      const auto dB_rel_PT_x = pAy * pz - pAz * py;
      const auto dB_rel_PT_y = pAz * px - pAx * pz;
      const auto dB_rel_PT_z = pAx * py - pAy * px;
      const auto dB_rel_PT =
        sqrtf(dB_rel_PT_x * dB_rel_PT_x + dB_rel_PT_y * dB_rel_PT_y + dB_rel_PT_z * dB_rel_PT_z) / p;

      // Save
      if (num_downstream_secondary_vertices[0] >= VertexFit::max_svs) break;
      const auto idx = atomicAdd(num_downstream_secondary_vertices, 1u);

      auto& sv = downstream_secondary_vertices[idx];

      sv.trk1 = daughterA_idx;
      sv.trk2 = daughterB_idx;
      sv.px = px;
      sv.py = py;
      sv.pz = pz;
      sv.x = vtx.x;
      sv.y = vtx.y;
      sv.z = vtx.z;
      sv.Armenteros_x = (dA_rel_Pl - dB_rel_Pl) / (dA_rel_Pl + dB_rel_Pl);
      sv.Armenteros_y = dA_rel_PT + dB_rel_PT;
      sv.doca = doca;
      sv.quality = quality_score;
    }
  }
}
