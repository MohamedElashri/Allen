/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <map>
#include <memory>
#include <optional>
#include <string>

#include "AllenUpdater.h"
#include <Dumpers/Identifiers.h>

namespace {
  using std::map;
  using std::optional;
  using std::string;
  using std::tuple;
  using std::unique_ptr;
  using std::vector;
} // namespace

DECLARE_COMPONENT( AllenUpdater )

void AllenUpdater::registerConsumer( string const& id, unique_ptr<Allen::NonEventData::Consumer> c ) {
  auto it = m_pairs.find( id );
  if ( it == m_pairs.end() ) {
    vector<unique_ptr<Allen::NonEventData::Consumer>> consumers( 1 );
    consumers[0] = std::move( c );
    auto entry   = tuple{Allen::NonEventData::Producer{}, std::move( consumers )};
    m_pairs.emplace( id, std::move( entry ) );
  } else {
    std::get<1>( it->second ).emplace_back( std::move( c ) );
  }
  if ( msgLevel( MSG::DEBUG ) ) { debug() << "Registered Consumer for " << id << endmsg; }
}

void AllenUpdater::registerProducer( string const& id, Allen::NonEventData::Producer p ) {
  auto it = m_pairs.find( id );
  if ( it == m_pairs.end() ) {
    auto entry = tuple{std::move( p ), std::vector<std::unique_ptr<Allen::NonEventData::Consumer>>{}};
    m_pairs.emplace( id, std::move( entry ) );
  } else if ( !std::get<0>( it->second ) ) {
    std::get<0>( it->second ) = std::move( p );
  } else {
    throw GaudiException{string{"Producer for "} + id, name(), StatusCode::FAILURE};
  }
  if ( msgLevel( MSG::DEBUG ) ) { debug() << "Registered Producer for " << id << endmsg; }
}

void AllenUpdater::update( unsigned long time ) {
  if ( msgLevel( MSG::DEBUG ) ) { debug() << "Running Update " << time << endmsg; }
  for ( auto const& entry : m_pairs ) {
    auto const& id = std::get<0>( entry );
    auto const& p  = std::get<1>( entry );

    if ( !std::get<0>( p ) ) {
      throw GaudiException{string{"No producer for "} + id, name(), StatusCode::FAILURE};
    } else if ( msgLevel( MSG::DEBUG ) && std::get<1>( p ).empty() ) {
      debug() << "No consumers for " << id << endmsg;
    }
  }
  for ( auto const& [id, pairs] : m_pairs ) {
    if ( msgLevel( MSG::DEBUG ) ) { debug() << "Updating " << id << endmsg; }
    if ( std::get<1>( pairs ).empty() ) continue;

    // Produce update
    auto update = std::get<0>( pairs )();
    if ( update ) {
      try {
        for ( auto& consumer : std::get<1>( pairs ) ) { consumer->consume( *update ); }
      } catch ( const GaudiException& e ) {
        error() << id << " update failed: " << e.message() << std::endl;
        throw e;
      }
    }
  }
}
