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
#include <vector>

#include <boost/filesystem.hpp>

#include <GaudiKernel/ParsersFactory.h>

#include <Event/RawBank.h>
#include <Event/RawEvent.h>
#include <Event/VPLightCluster.h>

#include "DumpRawBanks.h"
#include "Utils.h"

namespace {
  using std::to_string;

  namespace fs = boost::filesystem;
} // namespace

// Parsers are in namespace LHCb for ADL to work.
namespace LHCb {

  StatusCode parse( std::set<RawBank::BankType>& s, const std::string& in ) {
    std::set<std::string> ss;
    using Gaudi::Parsers::parse;
    auto sc = parse( ss, in );
    if ( !sc ) return sc;
    s.clear();
    try {
      std::transform( begin( ss ), end( ss ), std::inserter( s, begin( s ) ), []( const std::string& s ) {
        RawBank::BankType t{};
        auto              sc = parse( t, s );
        if ( !sc ) throw GaudiException( "Bad Parse", "", sc );
        return t;
      } );
    } catch ( const GaudiException& ge ) { return ge.code(); }
    return StatusCode::SUCCESS;
  }

  StatusCode parse( RawBank::BankType& result, const std::string& in ) {
    static std::unordered_map<std::string, RawBank::BankType> types;
    if ( types.empty() ) {
      for ( int t = 0; t < RawBank::LastType; ++t ) {
        auto bt = static_cast<RawBank::BankType>( t );
        types.emplace( RawBank::typeName( bt ), bt );
      }
    }

    // This takes care of quoting
    std::string input;
    using Gaudi::Parsers::parse;
    auto sc = parse( input, in );
    if ( !sc ) return sc;

    auto it = types.find( input );
    if ( it != end( types ) ) {
      result = it->second;
      return StatusCode::SUCCESS;
    } else {
      return StatusCode::FAILURE;
    }
  }

  inline std::ostream& toStream( const RawBank::BankType& bt, std::ostream& s ) {
    return s << "'" << RawBank::typeName( bt ) << "'";
  }
} // namespace LHCb

// Declaration of the Algorithm Factory
DECLARE_COMPONENT( DumpRawBanks )

DumpRawBanks::DumpRawBanks( const std::string& name, ISvcLocator* pSvcLocator )
    : Transformer( name, pSvcLocator,
                   // Inputs
                   {KeyValue{"RawEventLocation", LHCb::RawEventLocation::Default},
                    KeyValue{"ODINLocation", LHCb::ODINLocation::Default}},
                   // Output
                   KeyValue{"AllenRawInput", "Allen/Raw/Input"} ) {}

StatusCode DumpRawBanks::initialize() {
  info() << "Dumping RawBank Types:";
  for ( const auto bankType : m_bankTypes ) {
    auto tn = LHCb::RawBank::typeName( bankType );
    info() << " " << tn;
    if ( !DumpUtils::createDirectory( outputDirectory( bankType ) ) ) {
      error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
      return StatusCode::FAILURE;
    }
    m_histos[tn] = book1D( tn, -0.5, 603.5, 151 );
  }
  info() << endmsg;
  return StatusCode::SUCCESS;
}

std::array<std::vector<char>, LHCb::RawBank::LastType> DumpRawBanks::
                                                                                              operator()( const LHCb::RawEvent& rawEvent, const LHCb::ODIN& odin ) const {

  std::array<std::vector<char>, LHCb::RawBank::LastType> output;

  for ( const auto bankType : m_bankTypes ) {
    auto     tBanks             = rawEvent.banks( bankType );
    const uint32_t number_of_rawbanks = tBanks.size();
    uint32_t offset             = 0;

    std::vector<uint32_t> bankOffsets;
    std::vector<uint32_t> bankData;
    bankOffsets.push_back( 0 );
    
    for ( auto& bank : tBanks ) {
      const uint32_t sourceID = static_cast<uint32_t>( bank->sourceID() );
      bankData.push_back( sourceID );

      offset++;

      auto bStart = bank->begin<uint32_t>();
      auto bEnd   = bank->end<uint32_t>();

      // Debug/testing histogram with the sizes of the binary data per bank
      auto tn  = LHCb::RawBank::typeName( bankType );
      auto hit = m_histos.find( tn );
      if ( UNLIKELY( hit == end( m_histos ) ) ) {
        warning() << "No histogram booked for bank type " << tn << endmsg;
      } else {
        hit->second->fill( ( bEnd - bStart ) * sizeof( uint32_t ) );
      }

      while ( bStart != bEnd ) {
        const uint32_t raw_data = *( bStart );
        bankData.push_back( raw_data );

        bStart++;
        offset++;
      }
      bankOffsets.push_back( offset * sizeof( uint32_t ) );
    }
        
    // Dumping number_of_rawbanks + 1 offsets!
    DumpUtils::Writer bank_buffer;
    bank_buffer.write( number_of_rawbanks, bankOffsets, bankData );
    output[bankType] = bank_buffer.buffer();
    if ( m_dumpToFile ) {
      DumpUtils::FileWriter outfile = outputDirectory( bankType ) + "/" + to_string( odin.runNumber() ) + "_" + to_string( odin.eventNumber() ) + ".bin";
      outfile.write(bank_buffer.buffer());
    }
    
  }
  return output;
}

std::string DumpRawBanks::outputDirectory( LHCb::RawBank::BankType bankType ) const {
  auto tn  = LHCb::RawBank::typeName( bankType );
  auto dir = fs::path{m_outputDirectory.value()} / tn;
  return dir.string();
}
