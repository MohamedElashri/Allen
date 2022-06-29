/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RegisterConsumers.h"
#include "Common.h"
#include "BankTypes.h"

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
  const std::string magnet_string = "magnetic_field";

  std::tuple consumers = make_tuple(
    make_tuple(
      Allen::NonEventData::UTBoards {},
      std::make_unique<Consumers::HostDeviceGeometry>(constants.host_ut_boards, constants.dev_ut_boards),
      bank_name(BankTypes::UT)),
    make_tuple(
      Allen::NonEventData::UTLookupTables {},
      std::make_unique<Consumers::UTLookupTables>(constants.dev_ut_magnet_tool),
      bank_name(BankTypes::UT)),
    make_tuple(
      Allen::NonEventData::UTGeometry {}, std::make_unique<Consumers::UTGeometry>(constants), bank_name(BankTypes::UT)),
    make_tuple(
      Allen::NonEventData::SciFiGeometry {},
      std::make_unique<Consumers::HostDeviceGeometry>(constants.host_scifi_geometry, constants.dev_scifi_geometry),
      bank_name(BankTypes::FT)),
    make_tuple(
      Allen::NonEventData::MagneticField {},
      std::make_unique<Consumers::MagneticField>(constants.dev_magnet_polarity),
      magnet_string),
    make_tuple(
      Allen::NonEventData::Beamline {},
      std::make_unique<Consumers::Beamline>(constants.dev_beamline),
      bank_name(BankTypes::VP)),
    make_tuple(
      Allen::NonEventData::VeloGeometry {},
      std::make_unique<Consumers::VPGeometry>(constants),
      bank_name(BankTypes::VP)),
    make_tuple(
      Allen::NonEventData::ECalGeometry {},
      std::make_unique<Consumers::HostDeviceGeometry>(constants.host_ecal_geometry, constants.dev_ecal_geometry),
      bank_name(BankTypes::ECal)),
    make_tuple(
      Allen::NonEventData::MuonGeometry {},
      std::make_unique<Consumers::MuonGeometry>(
        constants.host_muon_geometry_raw, constants.dev_muon_geometry_raw, constants.dev_muon_geometry),
      bank_name(BankTypes::MUON)),
    make_tuple(
      Allen::NonEventData::MuonLookupTables {},
      std::make_unique<Consumers::MuonLookupTables>(
        constants.host_muon_lookup_tables_raw, constants.dev_muon_lookup_tables_raw, constants.dev_muon_tables),
      bank_name(BankTypes::MUON)));

  auto requested_banks = updater->requestedBanks();

  for_each(consumers, [updater, requested_banks](auto& c) {
    if (std::find(requested_banks.begin(), requested_banks.end(), std::get<2>(c)) != requested_banks.end()) {
      using id_t = typename std::remove_reference_t<decltype(std::get<0>(c))>;
      updater->registerConsumer<id_t>(std::move(std::get<1>(c)));
    }
  });
}
