/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <catch.hpp>
#include <Allen.h>
#include <zmq/svc.h>
#include <Updater.h>
#include <RunAllenTests.h>

int run_allen_on_magdown_dataset(const std::string& dataset_location)
{
  // Override some paths with source and build paths
  // Note: Test paths cannot be assumed to be "build"
  std::map<std::string, std::string> allen_options {};
  allen_options["g"] = source_directory + "/input/detector_configuration/down";
  allen_options["configuration"] = build_directory + "/Sequence.json";
  allen_options["f"] = dataset_location;
  append_default_allen_program_options(allen_options);
  Allen::NonEventData::Updater updater {allen_options};
  auto zmqSvc = makeZmqSvc();
  return allen(allen_options, &updater, zmqSvc, "");
}

TEST_CASE("Run Allen sequence " SEQUENCE " on default dataset", "[allenrun]")
{
  REQUIRE(run_allen_on_magdown_dataset(source_directory + "/input/minbias") == 0);
}

TEST_CASE("Run Allen sequence " SEQUENCE " on minbias mag down dataset", "[allenrun]")
{
  REQUIRE(run_allen_on_magdown_dataset(base_datadir + "/201907/minbias_mag_down") == 0);
}

TEST_CASE("Run Allen sequence " SEQUENCE " on BsPhiPhi mag down dataset", "[allenrun]")
{
  REQUIRE(run_allen_on_magdown_dataset(base_datadir + "/201907/bsphiphi_mag_down") == 0);
}

TEST_CASE("Run Allen sequence " SEQUENCE " on Ks02MuMu mag down dataset", "[allenrun]")
{
  REQUIRE(run_allen_on_magdown_dataset(base_datadir + "/201907/ks02mumu_mag_down") == 0);
}

TEST_CASE("Run Allen sequence " SEQUENCE " on JPsiMuMu mag down dataset", "[allenrun]")
{
  REQUIRE(run_allen_on_magdown_dataset(base_datadir + "/201907/jpsimumu_mag_down") == 0);
}
