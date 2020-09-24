/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <array>
#include <cstring>
#include <fstream>
#include <string>
#include <thread>

#include <boost/filesystem.hpp>

#include <AIDA/IHistogram1D.h>
#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <GaudiAlg/Consumer.h>
#include <GaudiKernel/ParsersFactory.h>

#include "Utils.h"

namespace {
  using std::to_string;

  namespace fs = boost::filesystem;
} // namespace

/** @class DumpRawBanks DumpRawBanks.h
 *  Algorithm that dumps raw banks to binary files.
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class DumpRawBanks : public Gaudi::Functional::Consumer<void(
                         std::array<std::vector<char>, LHCb::RawBank::LastType> const&, LHCb::ODIN const& )> {
public:
  /// Standard constructor
  DumpRawBanks( const std::string& name, ISvcLocator* pSvcLocator );

  StatusCode initialize() override;

  void operator()( std::array<std::vector<char>, LHCb::RawBank::LastType> const& banks,
                   LHCb::ODIN const&                                             odin ) const override;

private:
  std::string outputDirectory( LHCb::RawBank::BankType bankType ) const;

  mutable bool       m_createdDirectories{false};
  mutable std::mutex m_dirMutex;

  Gaudi::Property<std::string> m_outputDirectory{this, "OutputDirectory", "banks"};
};

DumpRawBanks::DumpRawBanks( const std::string& name, ISvcLocator* pSvcLocator )
    : Consumer(
          name, pSvcLocator,
          // Inputs
          {KeyValue{"BanksLocation", "Allen/Raw/Input"}, KeyValue{"ODINLocation", LHCb::ODINLocation::Default}} ) {}

StatusCode DumpRawBanks::initialize() {
  debug() << endmsg;
  return StatusCode::SUCCESS;
}

void DumpRawBanks::operator()( std::array<std::vector<char>, LHCb::RawBank::LastType> const& banks,
                               LHCb::ODIN const&                                             odin ) const {
  if ( !m_createdDirectories ) {
    std::lock_guard{m_dirMutex};
    if ( !m_createdDirectories ) {
      for ( int bt = 0; bt != LHCb::RawBank::LastType; ++bt ) {
        auto bankType = static_cast<LHCb::RawBank::BankType>( bt );
        if ( !banks[bankType].empty() ) {
          auto tn = LHCb::RawBank::typeName( bankType );
          if ( !DumpUtils::createDirectory( outputDirectory( bankType ) ) ) {
            throw GaudiException{"Failed to create directory " + m_outputDirectory.value(), name(),
                                 StatusCode::FAILURE};
          }
        }
      }
      m_createdDirectories = true;
    }
  }

  for ( int bt = 0; bt != LHCb::RawBank::LastType; ++bt ) {
    auto        bankType = static_cast<LHCb::RawBank::BankType>( bt );
    auto const& rawBanks = banks[bankType];
    if ( !rawBanks.empty() ) {
      DumpUtils::FileWriter outfile = outputDirectory( bankType ) + "/" + to_string( odin.runNumber() ) + "_" +
                                      to_string( odin.eventNumber() ) + ".bin";
      outfile.write( rawBanks );
    }
  }
}

std::string DumpRawBanks::outputDirectory( LHCb::RawBank::BankType bankType ) const {
  auto tn  = LHCb::RawBank::typeName( bankType );
  auto dir = fs::path{m_outputDirectory.value()} / tn;
  return dir.string();
}

// Declaration of the Algorithm Factory
DECLARE_COMPONENT( DumpRawBanks )
