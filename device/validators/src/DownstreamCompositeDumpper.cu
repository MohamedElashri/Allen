#include "DownstreamCompositeDumpper.cuh"

/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include <chrono>

INSTANTIATE_ALGORITHM(downstream_composite_dumper::downstream_composite_dumper_t)

namespace {
  __device__ inline Checker::Track make_checker_track(const Allen::Views::Physics::BasicParticle* track)
  {
    Checker::Track t;

    const auto num_hits = track->number_of_ids();
    for (unsigned int ihit = 0; ihit < num_hits; ihit++) {
      const auto id = track->id(ihit);
      t.addId(id);
    }
    return t;
  }

  __device__ inline float calculate_gamma(const float qop, const float magnet_polarity)
  {
    const auto abs_gamma = (3.669061E-08f) + (1.183515E-02f) * fabsf(qop) + (-1.974256E+00f) * qop * qop;

    const auto sign = -qop * magnet_polarity > 0 ? 1.f : -1.f;

    return sign * abs_gamma;
  }
} // namespace

__global__ void downstream_composite_dumper::downstream_composite_dumper(
  downstream_composite_dumper::Parameters parameters,
  const float* dev_magnet_polarity)
{
  constexpr auto NaN = std::numeric_limits<float>::quiet_NaN();

  // Basic
  const unsigned event_number = blockIdx.x;

  // Fill composites
  const auto composites = parameters.dev_multi_event_composites_view->container(event_number);
  auto checker_composites = parameters.dev_checker_composites + composites.offset();
  auto dumpping_objects = parameters.dev_dumpping_objects + composites.offset();
  {
    const auto num_composites = composites.size();
    for (unsigned composite_idx = threadIdx.x; composite_idx < num_composites; composite_idx += blockDim.x) {

      // Fetch data
      const auto composite = composites.particle(composite_idx);
      const auto secondary_vertex = composite.vertex();
      const auto dA = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(0));
      const auto dB = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(1));

      // Fill checker object
      Checker::Composite c;
      c.TrackA = make_checker_track(dA);
      c.TrackB = make_checker_track(dB);
      c.idx = composites.offset() + composite_idx;
      checker_composites[composite_idx] = c;

      // Fill dumpper
      Allen::DumppingObjects::DownstreamComposite dumpper;

      dumpper.x = secondary_vertex.x();
      dumpper.y = secondary_vertex.y();
      dumpper.z = secondary_vertex.z();
      dumpper.px = secondary_vertex.px();
      dumpper.py = secondary_vertex.py();
      dumpper.pz = secondary_vertex.pz();

      dumpper.pvx = composite.has_pv() ? composite.pv().position.x : NaN;
      dumpper.pvy = composite.has_pv() ? composite.pv().position.y : NaN;
      dumpper.pvz = composite.has_pv() ? composite.pv().position.z : NaN;

      dumpper.armenteros_x = secondary_vertex.downstream_armentero_podolanski_x();
      dumpper.armenteros_y = secondary_vertex.downstream_armentero_podolanski_y();

      dumpper.quality = secondary_vertex.downstream_quality();

      dumpper.ip = composite.ownpv_ip();
      dumpper.doca = secondary_vertex.downstream_doca();

      dumpper.fd = composite.fd();
      dumpper.ctau = composite.ctau();
      dumpper.dz = composite.dz();
      dumpper.drho = composite.drho();
      dumpper.eta = composite.eta();
      dumpper.mcor = composite.mcor();
      dumpper.minip = composite.minip();
      dumpper.minp = composite.minp();
      dumpper.minpt = composite.minpt();
      dumpper.maxp = composite.maxp();
      dumpper.maxpt = composite.maxpt();
      dumpper.dira = composite.dira();

      dumpper.dA.x = dA->state().x();
      dumpper.dA.y = dA->state().y();
      dumpper.dA.z = dA->state().z();
      dumpper.dA.tx = dA->state().tx();
      dumpper.dA.ty = dA->state().ty();
      dumpper.dA.g = calculate_gamma(dA->state().qop(), *dev_magnet_polarity);
      dumpper.dA.qop = dA->state().qop();
      dumpper.dA.chi2 = dA->state().chi2();
      dumpper.dA.ghost_prob = dA->track().ghost_probability();

      dumpper.dA.pvx = dA->pv().position.x;
      dumpper.dA.pvy = dA->pv().position.y;
      dumpper.dA.pvz = dA->pv().position.z;
      dumpper.dA.ip = dA->ownpv_ip();

      dumpper.dA.px = dA->state().px();
      dumpper.dA.py = dA->state().py();
      dumpper.dA.pz = dA->state().pz();
      dumpper.dA.pt = dA->state().pt();
      dumpper.dA.p = dA->state().p();
      dumpper.dA.eta = dA->state().eta();
      dumpper.dA.rho = dA->state().rho();

      dumpper.dA.is_electron = dA->is_electron();
      dumpper.dA.is_muon = dA->is_muon();

      dumpper.dB.x = dB->state().x();
      dumpper.dB.y = dB->state().y();
      dumpper.dB.z = dB->state().z();
      dumpper.dB.tx = dB->state().tx();
      dumpper.dB.ty = dB->state().ty();
      dumpper.dB.g = calculate_gamma(dB->state().qop(), *dev_magnet_polarity);
      dumpper.dB.qop = dB->state().qop();
      dumpper.dB.chi2 = dB->state().chi2();
      dumpper.dB.ghost_prob = dB->track().ghost_probability();

      dumpper.dB.pvx = dB->pv().position.x;
      dumpper.dB.pvy = dB->pv().position.y;
      dumpper.dB.pvz = dB->pv().position.z;
      dumpper.dB.ip = dB->ownpv_ip();

      dumpper.dB.px = dB->state().px();
      dumpper.dB.py = dB->state().py();
      dumpper.dB.pz = dB->state().pz();
      dumpper.dB.pt = dB->state().pt();
      dumpper.dB.p = dB->state().p();
      dumpper.dB.eta = dB->state().eta();
      dumpper.dB.rho = dB->state().rho();

      dumpper.dB.is_electron = dB->is_electron();
      dumpper.dB.is_muon = dB->is_muon();

      dumpping_objects[composite_idx] = dumpper;
      checker_composites[composite_idx] = c;
    }
  }
}

void downstream_composite_dumper::downstream_composite_dumper_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_dumpping_objects_t>(arguments, first<host_number_of_vertices_t>(arguments));
}

void downstream_composite_dumper::downstream_composite_dumper_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{

  global_function(downstream_composite_dumper)(first<host_number_of_events_t>(arguments), m_block_dim, context)(
    arguments, constants.dev_magnet_polarity.data());

  // Load result to host
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);
  const auto host_checker_composites = make_host_buffer<dev_checker_composites_t>(arguments, context);
  const auto host_dumpping_objects = make_host_buffer<dev_dumpping_objects_t>(arguments, context);
  const auto event_composites_offsets = make_host_buffer<dev_offset_vertices_t>(arguments, context);

  const auto host_downstream_mva_ks = make_host_buffer<dev_downstream_mva_ks_t>(arguments, context);
  const auto host_downstream_mva_l0 = make_host_buffer<dev_downstream_mva_l0_t>(arguments, context);
  const auto host_downstream_mva_detached_ks = make_host_buffer<dev_downstream_mva_detached_ks_t>(arguments, context);
  const auto host_downstream_mva_detached_l0 = make_host_buffer<dev_downstream_mva_detached_l0_t>(arguments, context);

  std::vector<Checker::Composites> composites;
  composites.resize(event_list.size());
  for (size_t i = 0; i < event_list.size(); ++i) {
    const auto evnum = event_list[i];
    const auto event_offset = event_composites_offsets[evnum];
    const auto n_tracks = event_composites_offsets[evnum + 1] - event_offset;
    std::vector<Checker::Composite> event_composites = {host_checker_composites.begin() + event_offset,
                                                        host_checker_composites.begin() + event_offset + n_tracks};
    composites[i] = event_composites;
  }

  // Obtain checker
  auto& checker = runtime_options.checker_invoker->checker<CompositeDumper>(name(), m_root_output_filename);

  // Fetch event level infos
  float host_polarity = 0;
  Allen::memcpy_async(
    &host_polarity, constants.dev_magnet_polarity.data(), sizeof(float), Allen::memcpyDeviceToHost, context);

  const auto slice_idx = static_cast<unsigned>(runtime_options.slice_index);
  const auto time = static_cast<unsigned>(
    (std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch())
       .count()) &
    0x7FFFFFFF);

  // Define tupling
  checker.accumulate<Checker::Subdetector::Downstream>(
    *first<host_mc_events_t>(arguments),
    composites,
    event_list,
    [slice_idx,
     time,
     host_polarity,
     &host_dumpping_objects,
     &host_downstream_mva_ks,
     &host_downstream_mva_l0,
     &host_downstream_mva_detached_ks,
     &host_downstream_mva_detached_l0](
      const unsigned event_idx,
      const Checker::Composite& composite,
      const CompositeDumper::MatchedComposite_t& matched,
      CompositeDumper::Columns_t& data) {
      // constexpr auto NaN = std::numeric_limits<float>::quiet_NaN();

      data["slice_idx"] = slice_idx;
      data["event_idx"] = event_idx;
      data["time"] = time;
      data["polarity"] = host_polarity;

      // Fetch dumpper
      const auto idx = composite.idx;
      const auto& dumpper = host_dumpping_objects[idx];

      // Extra info
      data["composite_kshort"] = host_downstream_mva_ks[idx];
      data["composite_lambda"] = host_downstream_mva_l0[idx];
      data["composite_detached_kshort"] = host_downstream_mva_detached_ks[idx];
      data["composite_detached_lambda"] = host_downstream_mva_detached_l0[idx];

      //
      // Fill reconstructed info
      //
      data["composite_x"] = dumpper.x;
      data["composite_y"] = dumpper.y;
      data["composite_z"] = dumpper.z;
      data["composite_px"] = dumpper.px;
      data["composite_py"] = dumpper.py;
      data["composite_pz"] = dumpper.pz;
      data["composite_pvx"] = dumpper.pvx;
      data["composite_pvy"] = dumpper.pvy;
      data["composite_pvz"] = dumpper.pvz;
      data["composite_ip"] = dumpper.ip;
      data["composite_doca"] = dumpper.doca;
      data["composite_fd"] = dumpper.fd;
      data["composite_ctau"] = dumpper.ctau;
      data["composite_dz"] = dumpper.dz;
      data["composite_drho"] = dumpper.drho;
      data["composite_eta"] = dumpper.eta;
      data["composite_mcor"] = dumpper.mcor;
      data["composite_minip"] = dumpper.minip;
      data["composite_minp"] = dumpper.minp;
      data["composite_minpt"] = dumpper.minpt;
      data["composite_maxp"] = dumpper.maxp;
      data["composite_maxpt"] = dumpper.maxpt;
      data["composite_dira"] = dumpper.dira;

      data["composite_armenteros_x"] = dumpper.armenteros_x;
      data["composite_armenteros_y"] = dumpper.armenteros_y;
      data["composite_quality"] = dumpper.quality;

      data["dA_x"] = dumpper.dA.x;
      data["dA_y"] = dumpper.dA.y;
      data["dA_z"] = dumpper.dA.z;
      data["dA_tx"] = dumpper.dA.tx;
      data["dA_ty"] = dumpper.dA.ty;
      data["dA_g"] = dumpper.dA.g;
      data["dA_qop"] = dumpper.dA.qop;
      data["dA_chi2"] = dumpper.dA.chi2;
      data["dA_pvx"] = dumpper.dA.pvx;
      data["dA_pvy"] = dumpper.dA.pvy;
      data["dA_pvz"] = dumpper.dA.pvz;
      data["dA_ip"] = dumpper.dA.ip;
      data["dA_px"] = dumpper.dA.px;
      data["dA_py"] = dumpper.dA.py;
      data["dA_pz"] = dumpper.dA.pz;
      data["dA_pt"] = dumpper.dA.pt;
      data["dA_p"] = dumpper.dA.p;
      data["dA_eta"] = dumpper.dA.eta;
      data["dA_rho"] = dumpper.dA.rho;
      data["dA_ghost"] = dumpper.dA.ghost_prob;

      data["dA_is_muon"] = dumpper.dA.is_muon;
      data["dA_is_electron"] = dumpper.dA.is_electron;

      data["dB_x"] = dumpper.dB.x;
      data["dB_y"] = dumpper.dB.y;
      data["dB_z"] = dumpper.dB.z;
      data["dB_tx"] = dumpper.dB.tx;
      data["dB_ty"] = dumpper.dB.ty;
      data["dB_g"] = dumpper.dB.g;
      data["dB_qop"] = dumpper.dB.qop;
      data["dB_chi2"] = dumpper.dB.chi2;
      data["dB_pvx"] = dumpper.dB.pvx;
      data["dB_pvy"] = dumpper.dB.pvy;
      data["dB_pvz"] = dumpper.dB.pvz;
      data["dB_ip"] = dumpper.dB.ip;
      data["dB_px"] = dumpper.dB.px;
      data["dB_py"] = dumpper.dB.py;
      data["dB_pz"] = dumpper.dB.pz;
      data["dB_pt"] = dumpper.dB.pt;
      data["dB_p"] = dumpper.dB.p;
      data["dB_eta"] = dumpper.dB.eta;
      data["dB_rho"] = dumpper.dB.rho;
      data["dB_ghost"] = dumpper.dB.ghost_prob;

      data["dB_is_muon"] = dumpper.dB.is_muon;
      data["dB_is_electron"] = dumpper.dB.is_electron;

      //
      // Fill truth matching infos
      //
      const auto category = matched.category;
      const auto mcp_A = matched.trackA;
      const auto mcp_B = matched.trackB;

      data["category"] = category;

      if (category == 0) {
        data["true_x"] = mcp_A->ovtx_x;
        data["true_y"] = mcp_A->ovtx_y;
        data["true_z"] = mcp_A->ovtx_z;
        data["true_px"] = (mcp_A->pt * cosf(mcp_A->phi)) + (mcp_B->pt * cosf(mcp_B->phi));
        data["true_py"] = (mcp_A->pt * sinf(mcp_A->phi)) + (mcp_B->pt * sinf(mcp_B->phi));
        data["true_pz"] = (mcp_A->pt * sinhf(mcp_A->phi)) + (mcp_B->pt * sinhf(mcp_B->phi));
        data["true_pid"] = mcp_A->mother_pid;
        data["true_key"] = mcp_A->motherKey;
        data["true_fromSignal"] = mcp_A->fromSignal;
        data["true_OriginKey"] = mcp_A->DecayOriginMother_key;
      }
      else {
        data["true_x"] = std::numeric_limits<float>::quiet_NaN();
        data["true_y"] = std::numeric_limits<float>::quiet_NaN();
        data["true_z"] = std::numeric_limits<float>::quiet_NaN();
        data["true_px"] = std::numeric_limits<float>::quiet_NaN();
        data["true_py"] = std::numeric_limits<float>::quiet_NaN();
        data["true_pz"] = std::numeric_limits<float>::quiet_NaN();
        data["true_pid"] = 0;
        data["true_fromSignal"] = false;
        data["true_key"] = -1;
        data["true_OriginKey"] = -1;
      }

      auto fill_mcp = [&data](const std::string prefix, const MCParticle* mcp) {
        if (mcp) {
          data[prefix + "_true_hasVelo"] = mcp->hasVelo;
          data[prefix + "_true_hasUT"] = mcp->hasUT;
          data[prefix + "_true_hasSciFi"] = mcp->hasSciFi;
          data[prefix + "_true_isLong"] = mcp->isLong;
          data[prefix + "_true_isDown"] = mcp->isDown;
          data[prefix + "_true_fromSignal"] = mcp->fromSignal;
          data[prefix + "_true_pid"] = mcp->pid;
          data[prefix + "_true_mother_pid"] = mcp->mother_pid;
          data[prefix + "_true_origin_pid"] = mcp->DecayOriginMother_pid;
          data[prefix + "_true_mother_key"] = mcp->motherKey;
          data[prefix + "_true_origin_key"] = mcp->DecayOriginMother_key;
          data[prefix + "_true_p"] = mcp->p;
          data[prefix + "_true_pt"] = mcp->pt;
          data[prefix + "_true_eta"] = mcp->eta;
          data[prefix + "_true_phi"] = mcp->phi;
          data[prefix + "_true_px"] = mcp->pt * cosf(mcp->phi);
          data[prefix + "_true_py"] = mcp->pt * sinf(mcp->phi);
          data[prefix + "_true_pz"] = mcp->pt * sinhf(mcp->eta);
        }
        else {
          data[prefix + "_true_hasVelo"] = false;
          data[prefix + "_true_hasUT"] = false;
          data[prefix + "_true_hasSciFi"] = false;
          data[prefix + "_true_isLong"] = false;
          data[prefix + "_true_isDown"] = false;
          data[prefix + "_true_fromSignal"] = false;
          data[prefix + "_true_pid"] = 0;
          data[prefix + "_true_mother_pid"] = 0;
          data[prefix + "_true_origin_pid"] = 0;
          data[prefix + "_true_mother_key"] = -1;
          data[prefix + "_true_origin_key"] = -1;
          data[prefix + "_true_p"] = std::numeric_limits<float>::quiet_NaN();
          data[prefix + "_true_pt"] = std::numeric_limits<float>::quiet_NaN();
          data[prefix + "_true_eta"] = std::numeric_limits<float>::quiet_NaN();
          data[prefix + "_true_phi"] = std::numeric_limits<float>::quiet_NaN();
          data[prefix + "_true_px"] = std::numeric_limits<float>::quiet_NaN();
          data[prefix + "_true_py"] = std::numeric_limits<float>::quiet_NaN();
          data[prefix + "_true_pz"] = std::numeric_limits<float>::quiet_NaN();
        }
      };

      fill_mcp("dA", mcp_A);
      fill_mcp("dB", mcp_B);

      // For partial ghost case, we assign the veretex info from the non-ghost track
      if (category == 3) {
        const auto mcp = mcp_A ? mcp_A : mcp_B;
        data["true_pid"] = mcp->pid;
        data["true_key"] = mcp->motherKey;
        data["true_fromSignal"] = mcp->fromSignal;
        data["true_OriginKey"] = mcp->DecayOriginMother_key;
      }
    },
    // Composite Filter
    [](
      const unsigned, const Checker::Composite&, const CompositeDumper::MatchedComposite_t& // matched
    ) {
      // return (matched.category == 0)&&((abs(matched.trackA->mother_pid) == 3122)||(abs(matched.trackA->mother_pid) ==
      // 310));
      return true;
    },
    // Event filter (Has reconstructible downstream tracks)
    [](const unsigned, const MCEvent&) { return true; });
}