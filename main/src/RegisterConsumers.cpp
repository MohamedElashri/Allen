/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <RegisterConsumers.h>
#include <Common.h>
#include <Updater.h>

/**
 * @brief      Register all consumers of non-event data
 *
 * @param      IUpdater instance
 * @param      Constants
 *
 * @return     void
 */
void register_consumers(
  Allen::NonEventData::IUpdater* updater,
  Constants& constants,
  const std::unordered_set<BankTypes> requested_banks)
{
  const auto consumers = std::make_tuple(
    std::make_tuple(
      Allen::NonEventData::UTBoards {},
      [&constants]() {
        return std::make_unique<Consumers::HostDeviceGeometry>(constants.host_ut_boards, constants.dev_ut_boards);
      },
      BankTypes::UT),
    std::make_tuple(
      Allen::NonEventData::UTLookupTables {},
      [&constants]() { return std::make_unique<Consumers::UTLookupTables>(constants.dev_ut_magnet_tool); },
      BankTypes::UT),
    std::make_tuple(
      Allen::NonEventData::UTGeometry {},
      [&constants]() { return std::make_unique<Consumers::UTGeometry>(constants); },
      BankTypes::UT),
    std::make_tuple(
      Allen::NonEventData::SciFiGeometry {},
      [&constants]() {
        return std::make_unique<Consumers::HostDeviceGeometry>(
          constants.host_scifi_geometry, constants.dev_scifi_geometry);
      },
      BankTypes::FT),
    std::make_tuple(
      Allen::NonEventData::Beamline {},
      [&constants]() { return std::make_unique<Consumers::Beamline>(constants.dev_beamline); },
      BankTypes::VP),
    std::make_tuple(
      Allen::NonEventData::VeloGeometry {},
      [&constants]() { return std::make_unique<Consumers::VPGeometry>(constants); },
      BankTypes::VP),
    std::make_tuple(
      Allen::NonEventData::ECalGeometry {},
      [&constants]() {
        return std::make_unique<Consumers::HostDeviceGeometry>(
          constants.host_ecal_geometry, constants.dev_ecal_geometry);
      },
      BankTypes::ECal),
    std::make_tuple(
      Allen::NonEventData::MuonGeometry {},
      [&constants]() {
        return std::make_unique<Consumers::MuonGeometry>(
          constants.host_muon_geometry_raw, constants.dev_muon_geometry_raw, constants.dev_muon_geometry);
      },
      BankTypes::MUON),
    std::make_tuple(
      Allen::NonEventData::MuonLookupTables {},
      [&constants]() {
        return std::make_unique<Consumers::MuonLookupTables>(
          constants.host_muon_lookup_tables_raw, constants.dev_muon_lookup_tables_raw, constants.dev_muon_tables);
      },
      BankTypes::MUON));

  const auto unconditional_consumers =
    std::make_tuple(std::make_tuple(Allen::NonEventData::MagneticField {}, [&constants]() {
      return std::make_unique<Consumers::MagneticField>(constants.dev_magnet_polarity);
    }));

  for_each(consumers, [updater, requested_banks](const auto& c) {
    if (requested_banks.count(std::get<2>(c))) {
      using id_t = typename std::remove_reference_t<decltype(std::get<0>(c))>;
      updater->registerConsumer<id_t>(std::get<1>(c)());
    }
  });

  for_each(unconditional_consumers, [updater](const auto& c) {
    using id_t = typename std::remove_reference_t<decltype(std::get<0>(c))>;
    updater->registerConsumer<id_t>(std::get<1>(c)());
  });
}

Allen::NonEventData::IUpdater* binary_updater(std::map<std::string, std::string> const& options)
{
  static std::unique_ptr<Allen::NonEventData::IUpdater> updater;
  if (!updater) {
    updater = std::make_unique<Allen::NonEventData::Updater>(options);
  }
  return updater.get();
}
