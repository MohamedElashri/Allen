/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "KsToPiPiLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"
INSTANTIATE_LINE(kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters)

void kstopipi_line::kstopipi_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<typename Parameters::dev_decisions_t>(
    arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::dev_decisions_offsets_t>(
    arguments, first<typename Parameters::host_number_of_events_t>(arguments));
  set_size<typename Parameters::host_post_scaler_t>(arguments, 1);
  set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);
  set_size<typename Parameters::host_lhcbid_container_t>(arguments, 1);

  set_size<typename Parameters::dev_sv_masses_t>(
    arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_sv_masses_t>(
    arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_pt_t>(arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_pt_t>(arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));
}
__device__ bool kstopipi_line::kstopipi_line_t::select(
  const Parameters&,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vertex = std::get<0>(input);
  return vertex.minipchi2 > 100 && vertex.chi2 < 10 && vertex.vertex_ip < 0.3f && vertex.m(139.57, 139.57) > 400 &&
         vertex.m(139.57, 139.57) < 600;
}

#ifdef WITH_ROOT
void kstopipi_line::kstopipi_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  initialize<dev_sv_masses_t>(arguments, -1, context);
  initialize<dev_pt_t>(arguments, -1, context);
}

__device__ void kstopipi_line::kstopipi_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input,
  unsigned index,
  bool sel)
{
  const auto& vertex = std::get<0>(input);
  if (sel) {
    // printf("Event selected!! \n");
    parameters.dev_sv_masses[index] = vertex.m(139.57, 139.57);
    parameters.dev_pt[index] = vertex.pt();
  }
}

void kstopipi_line::kstopipi_line_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{

  auto name_str = name();
  std::string name_ttree = "monitor_tree" + name_str;
  Allen::copy<host_sv_masses_t, dev_sv_masses_t>(arguments, context);
  Allen::copy<host_pt_t, dev_pt_t>(arguments, context);
  Allen::synchronize(context);

  auto handler = runtime_options.root_service->handle();
  handler.file("monitor.root");

  auto tree = handler.ttree(name_ttree.c_str());

  float mass;
  float pt;
  int ev;

  handler.branch("mass", mass);
  handler.branch("pt", pt);
  handler.branch("ev", ev);

  unsigned n_svs = size<host_sv_masses_t>(arguments);
  float* sv_mass;
  float* sv_pt;
  int i0 = tree->GetEntries();
  for (unsigned i = 0; i < n_svs; i++) {
    sv_mass = data<host_sv_masses_t>(arguments) + i;
    sv_pt = data<host_pt_t>(arguments) + i;
    if (sv_mass[0] > 0) {
      mass = sv_mass[0];
      pt = sv_pt[0];
      ev = i0 + i;
      tree->Fill();
    }
  }
  tree->Write(0, TObject::kOverwrite);
}
#endif
