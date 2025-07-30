/*****************************************************************************\
 * (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
 \*****************************************************************************/
#include "ReconstructibleSignalCounter.h"
#include "PrepareTracks.h"

INSTANTIATE_ALGORITHM(reconstructible_signal_counter::reconstructible_signal_counter_t)

void reconstructible_signal_counter::reconstructible_signal_counter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);

  auto handler = runtime_options.root_service->handle("MCReconstructibleInfo");
  auto tree = handler.tree("monitor_tree");
  if (tree == nullptr) return;

  auto mc_events = *first<host_mc_events_t>(arguments);

  uint64_t eventNumber;
  unsigned runNumber;
  unsigned nReconstructible;
  unsigned nDownstreamReconstructible;
  unsigned nLongReconstructible;
  handler.branch(tree, "eventNumber", eventNumber);
  handler.branch(tree, "runNumber", runNumber);
  handler.branch(tree, "nReconstructible", nReconstructible);
  handler.branch(tree, "nLongReconstructible", nLongReconstructible);
  handler.branch(tree, "nDownReconstructible", nDownstreamReconstructible);

  for (unsigned event_number = 0; event_number != mc_events.size(); ++event_number) {
    LHCb::ODIN odin {data<host_odin_data_t>(arguments)[event_number]};
    eventNumber = odin.eventNumber();
    runNumber = odin.runNumber();
    nReconstructible = 0;
    nDownstreamReconstructible = 0;
    nLongReconstructible = 0;
    for (const auto& mcp : mc_events[event_number].m_mcps) {
      if (!mcp.fromSignal) continue;
      nReconstructible += (mcp.isLong || mcp.isDown);
      nLongReconstructible += (mcp.isLong);
      nDownstreamReconstructible += (mcp.isDown && !mcp.isLong);
    }
    tree->Fill();
  }
}
