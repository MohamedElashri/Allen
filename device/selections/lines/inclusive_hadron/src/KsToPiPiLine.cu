/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "KsToPiPiLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"
INSTANTIATE_LINE(kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters)

void kstopipi_line::kstopipi_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, runtime_options, constants, host_buffers);

  set_size<dev_sv_masses_t>(arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));
  set_size<host_sv_masses_t>(arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));

  set_size<dev_pt_t>(arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));
  set_size<host_pt_t>(arguments, kstopipi_line::kstopipi_line_t::get_decisions_size(arguments));
}
__device__ bool kstopipi_line::kstopipi_line_t::select(
  const Parameters&,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vertex = std::get<0>(input);
  return vertex.minipchi2 > 100 && vertex.chi2 < 10 && vertex.vertex_ip < 0.3f &&
         vertex.m(Allen::mPi, Allen::mPi) > 400 && vertex.m(Allen::mPi, Allen::mPi) < 600;
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
    parameters.dev_sv_masses[index] = vertex.m(Allen::mPi, Allen::mPi);
    parameters.dev_pt[index] = vertex.pt();
  }
}

void kstopipi_line::kstopipi_line_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{
  if (!property<make_tuple_t>()) return;

  auto handler = runtime_options.root_service->handle(name());
  auto tree = handler.tree("monitor_tree");
  if (tree == nullptr) return;

  Allen::copy<host_sv_masses_t, dev_sv_masses_t>(arguments, context);
  Allen::copy<host_pt_t, dev_pt_t>(arguments, context);
  Allen::synchronize(context);

  float mass;
  float pt;
  size_t ev;

  handler.branch(tree, "mass", mass);
  handler.branch(tree, "pt", pt);
  handler.branch(tree, "ev", ev);

  unsigned n_svs = size<host_sv_masses_t>(arguments);
  float* sv_mass;
  float* sv_pt;
  size_t i0 = tree->GetEntries();
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
}
#endif
