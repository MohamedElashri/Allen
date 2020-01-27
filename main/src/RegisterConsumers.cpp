#include "RegisterConsumers.h"
#include "Common.h"

/**
 * @brief      Register all consumers of non-event data
 *
 * @param      IUpdater instance
 * @param      Constants
 *
 * @return     void
 */
void register_consumers(Allen::NonEventData::IUpdater* updater, Constants& constants)
{
  std::tuple consumers = make_tuple(
    make_tuple(Allen::NonEventData::UTBoards {}, std::make_unique<Consumers::BasicGeometry>(constants.dev_ut_boards)),
    make_tuple(
      Allen::NonEventData::UTLookupTables {},
      std::make_unique<Consumers::UTLookupTables>(constants.dev_ut_magnet_tool)),
    make_tuple(Allen::NonEventData::UTGeometry {}, std::make_unique<Consumers::UTGeometry>(constants)),
    make_tuple(
      Allen::NonEventData::SciFiGeometry {},
      std::make_unique<Consumers::SciFiGeometry>(constants.host_scifi_geometry, constants.dev_scifi_geometry)),
    make_tuple(
      Allen::NonEventData::MagneticField {}, std::make_unique<Consumers::MagneticField>(constants.dev_magnet_polarity)),
    make_tuple(Allen::NonEventData::Beamline {}, std::make_unique<Consumers::Beamline>(constants.dev_beamline)),
    make_tuple(Allen::NonEventData::VeloGeometry {}, std::make_unique<Consumers::VPGeometry>(constants)),
    make_tuple(
      Allen::NonEventData::MuonGeometry {},
      std::make_unique<Consumers::MuonGeometry>(
        constants.host_muon_geometry_raw, constants.dev_muon_geometry_raw, constants.dev_muon_geometry)),
    make_tuple(
      Allen::NonEventData::MuonLookupTables {},
      std::make_unique<Consumers::MuonLookupTables>(
        constants.host_muon_lookup_tables_raw, constants.dev_muon_lookup_tables_raw, constants.dev_muon_tables)));

  for_each(consumers, [updater](auto& c) {
    using id_t = typename std::remove_reference_t<decltype(std::get<0>(c))>;
    updater->registerConsumer<id_t>(std::move(std::get<1>(c)));
  });
}
