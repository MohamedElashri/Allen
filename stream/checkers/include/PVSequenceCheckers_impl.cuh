#include "PrimaryVertexChecker.h"

/**
 * @brief Specialization for patPV PV finding algorithm
 */
// template<>
// void SequenceVisitor::check<pv_fit_seeds_t>(
//   HostBuffers& host_buffers,
//   const Constants&,
//   const CheckerInvoker& checker_invoker,
//   const MCEvents& mc_events) const
// {
//   auto& checker = checker_invoker.checker<GPUPVChecker>("Primary vertices (pv_fit_seeds_t):", "GPU_PVChecker.root");
//   checker.accumulate(
//     mc_events,
//     host_buffers.host_reconstructed_pvs,
//     host_buffers.host_number_of_vertex,
//     value<host_number_of_selected_events_t>(arguments));
// }

/**
 * @brief Specialization for beamline PV finding algorithm on GPU
 */
// template<>
// void SequenceVisitor::check<pv_beamline_cleanup_t>(
//   HostBuffers& host_buffers,
//   const Constants&,
//   const CheckerInvoker& checker_invoker,
//   const MCEvents& mc_events) const
// {
//   auto& checker = checker_invoker.checker<GPUPVChecker>("Primary vertices:", "GPU_PVChecker.root");
//   checker.accumulate(
//     mc_events,
//     host_buffers.host_reconstructed_multi_pvs,
//     host_buffers.host_number_of_multivertex,
//     value<host_number_of_selected_events_t>(arguments));
// }
