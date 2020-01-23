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
#ifndef DUMPRAWBANKS_H
#define DUMPRAWBANKS_H 1

#include <cstring>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>

// Include files
#include "GaudiAlg/Transformer.h"
#include <AIDA/IHistogram1D.h>
#include <Event/ODIN.h>
#include <Event/RawBank.h>
#include <Event/RawEvent.h>
#include <GaudiAlg/GaudiHistoAlg.h>

// Parsers for the bank type property are put in namespace LHCb for
// ADL to work.
namespace LHCb {

  StatusCode parse( RawBank::BankType& result, const std::string& in );
  StatusCode parse( std::set<RawBank::BankType>& s, const std::string& in );
} // namespace LHCb

// Raw bank format:
// -----------------------------------------------------------------------------
// name                |  type    |  size [bytes]         | array_size
// =============================================================================
// Once
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// number_of_rawbanks  | uint32_t | 4
// -----------------------------------------------------------------------------
// raw_bank_offset     | uint32_t | number_of_rawbanks * 4
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// for each raw bank:
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// sourceID            | uint32_t | 4                     |
// ------------------------------------------------------------------------------
// bank_data           | char     | variable
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/** @class DumpRawBanks DumpRawBanks.h
 *  Algorithm that dumps raw banks to binary files.
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
class DumpRawBanks : public Gaudi::Functional::Transformer<
std::array<std::vector<char>, LHCb::RawBank::LastType>(
                             const LHCb::RawEvent&, const LHCb::ODIN& ),
                         Gaudi::Functional::Traits::BaseClass_t<GaudiHistoAlg>> {
public:
  /// Standard constructor
  DumpRawBanks( const std::string& name, ISvcLocator* pSvcLocator );

  StatusCode initialize() override;

  std::array<std::vector<char>, LHCb::RawBank::LastType>
  operator()( const LHCb::RawEvent& rawEvent, const LHCb::ODIN& odin ) const override;

private:
  std::string outputDirectory( LHCb::RawBank::BankType bankType ) const;

  Gaudi::Property<std::string>                       m_outputDirectory{this, "OutputDirectory", "banks"};
  Gaudi::Property<std::set<LHCb::RawBank::BankType>> m_bankTypes{
      this, "BankTypes", {LHCb::RawBank::VP, LHCb::RawBank::UT, LHCb::RawBank::FTCluster, LHCb::RawBank::Muon}};
  Gaudi::Property<bool> m_dumpToFile{this, "DumpToFile", true};

  std::unordered_map<std::string, AIDA::IHistogram1D*> m_histos;
};
#endif // DUMPRAWBANKS_H
