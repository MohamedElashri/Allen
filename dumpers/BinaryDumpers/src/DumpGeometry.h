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
#ifndef DUMPGEOMETRY_H
#define DUMPGEOMETRY_H 1

#include <cstring>
#include <fstream>
#include <regex>
#include <string>
#include <vector>

#include <boost/filesystem.hpp>

#include <DetDesc/DetectorElement.h>
#include <Gaudi/Parsers/Factory.h>
#include <GaudiAlg/GetData.h>
#include <GaudiKernel/GaudiException.h>
#include <GaudiKernel/IDataProviderSvc.h>
#include <GaudiKernel/IUpdateManagerSvc.h>
#include <GaudiKernel/Service.h>
#include <Kernel/ICondDBInfo.h>

#include "Utils.h"
#include <Dumpers/IUpdater.h>
#include <Dumpers/Identifiers.h>

/** @class DumpGeometry
 *  Base class for a Service that dumps a subdetector's geometry
 *
 *  @author Roel Aaij
 *  @date   2018-08-27
 */
template <typename DETECTOR>
class DumpGeometry : public Service {
public:
  DumpGeometry( std::string name, ISvcLocator* loc, std::string detLoc )
      : Service( name, loc ), m_location{std::move( detLoc )} {}

  StatusCode initialize() override;

  StatusCode dump();

  inline void Assert( const bool ok, const std::string& message = "",
                      const StatusCode sc = StatusCode( StatusCode::FAILURE, true ) ) const {
    if ( !ok ) throw GaudiException( this->name() + ":: " + message, "", sc );
  }

protected:
  virtual StatusCode registerConditions( IUpdateManagerSvc* ) { return StatusCode::SUCCESS; }

  virtual DumpUtils::Dumps dumpGeometry() const = 0;

  std::string outputDirectory() const { return m_outputDirectory.value(); }
  std::string geometrySuffix() const;

  const DETECTOR& detector() const { return *m_det; }
  DETECTOR&       detector() { return *( const_cast<DumpGeometry<DETECTOR>*>( this )->m_det ); }

  SmartIF<IDataProviderSvc> detSvc() const { return m_detSvc; }

  template <typename DET, std::enable_if_t<std::is_base_of<DetectorElement, DET>::value>* = nullptr>
  void get( std::string location, IUpdateManagerSvc* updMgrSvc ) {
    m_det = getDet<DETECTOR>( location );
    // Register our callback to trigger the actual dumping
    updMgrSvc->registerCondition( this, m_det->geometry(), &DumpGeometry<DETECTOR>::dump );
  }

  template <typename DET,
            std::enable_if_t<std::is_base_of<Condition, DET>::value || std::is_same<Condition, DET>::value>* = nullptr>
  void get( std::string location, IUpdateManagerSvc* updMgrSvc ) {
    m_det = getDet<DETECTOR>( location );
    // Register our callback to trigger the actual dumping
    updMgrSvc->registerCondition( this, location, &DumpGeometry<DETECTOR>::dump );
  }

  template <typename DET, std::enable_if_t<std::is_base_of<IService, DET>::value>* = nullptr>
  void get( std::string location, IUpdateManagerSvc* updMgrSvc ) {
    m_det = service<DETECTOR>( location, true );
    // Register our callback to trigger the actual dumping
    updMgrSvc->registerCondition( this, m_det, &DumpGeometry<DETECTOR>::dump );
  }

  template <typename DET, std::enable_if_t<std::is_base_of<IAlgTool, DET>::value>* = nullptr>
  void get( std::string location, IUpdateManagerSvc* updMgrSvc ) {
    m_det = tool<DETECTOR>( location, true );
    // Register our callback to trigger the actual dumping
    updMgrSvc->registerCondition( this, m_det, &DumpGeometry<DETECTOR>::dump );
  }

  template <class TOOL>
  inline TOOL* tool( const std::string& type, bool create = true ) const {
    return tool<TOOL>( type, type, create );
  }

  template <class TOOL>
  inline TOOL* tool( const std::string& type, const std::string& name, bool create = true ) const {
    // for empty names delegate to another method
    if ( name.empty() ) return tool<TOOL>( type, create );
    Assert( m_toolSvc.isValid(), "tool():: IToolSvc* points to NULL!" );
    // get the tool from Tool Service
    TOOL*      t  = nullptr;
    const auto sc = m_toolSvc->retrieveTool( type, name, t, m_toolSvc, create );
    if ( sc.isFailure() ) {
      throw GaudiException( this->name() + ":: " + "tool():: Could not retrieve Tool '" + type + "'/'" + name + "'", "",
                            sc );
    }
    if ( !t ) {
      throw GaudiException( this->name() + ":: " + "tool():: Could not retrieve Tool '" + type + "'/'" + name + "'", "",
                            sc );
    }
    return t;
  }

  template <class T>
  typename Gaudi::Utils::GetData<T>::return_type getDet( std::string location ) const {
    Gaudi::Utils::GetData<T> getter{};
    auto                     info = getter( *this, m_detSvc, location );
    if ( !info ) {
      error() << "Could not obtain detector data from " << location << endmsg;
      return nullptr;
    } else {
      return info;
    }
  }

private:
  Gaudi::Property<std::string>                         m_outputDirectory{this, "OutputDirectory", "geometry"};
  Gaudi::Property<std::pair<std::string, std::string>> m_tagRegex{
      this, "TagRegex", make_pair( std::string{".*/(\\w+)\\.git"}, std::string{".*/([a-zA-Z0-9\\-]+)\\[(.*)\\]"} )};
  std::string                                        m_location;
  std::unordered_map<std::string, std::vector<char>> m_buffer;

  std::map<std::string, std::string> m_tags;
  Gaudi::Property<bool>              m_dumpToFile{this, "DumpToFile", true};
  Gaudi::Property<std::string>       m_updaterName{this, "UpdaterName", "AllenUpdater"};

  SmartIF<IDataProviderSvc> m_detSvc;
  SmartIF<ICondDBInfo>      m_condDBInfo;
  SmartIF<IToolSvc>         m_toolSvc;

  DETECTOR* m_det;
};

template <typename DETECTOR>
StatusCode DumpGeometry<DETECTOR>::initialize() {
  if ( !DumpUtils::createDirectory( m_outputDirectory.value() ) ) {
    error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
    return StatusCode::FAILURE;
  }

  // Facilitate derived services getting tools
  m_toolSvc = service( "ToolSvc", true );

  // Get the DB tags in use
  m_condDBInfo = service( "XmlParserSvc", true );
  std::vector<LHCb::CondDBNameTagPair> tags;
  m_condDBInfo->defaultTags( tags );
  std::regex partRegex( m_tagRegex.value().first );
  std::regex tagRegex( m_tagRegex.value().second );
  for ( auto&& entry : tags ) {
    std::string partition = entry.first, tag = entry.second, commit;
    std::smatch result;
    auto        r = std::regex_match( partition, result, partRegex );
    if ( r ) { partition = result[1].str(); }
    r = std::regex_match( tag, result, tagRegex );
    if ( r && result[1].str() != "master" ) {
      tag = result[1].str();
    } else if ( r ) {
      // If the master tag is used, store the commit ID to pin it down.
      tag = result[1].str() + "[" + result[2].str() + "]";
    }
    auto e = m_tags.emplace( std::move( partition ), std::move( tag ) );
    if ( msgLevel( MSG::DEBUG ) ) { debug() << "tag: " << e.first->first << " " << e.first->second << endmsg; }
  }

  // Get the requested detector
  m_detSvc = service( "DetectorDataSvc", true );
  if ( !m_detSvc.isValid() ) {
    error() << "Unable to obtain detector data service." << endmsg;
    return StatusCode::FAILURE;
  }

  auto updMgrSvc = service( "UpdateManagerSvc", true ).template as<IUpdateManagerSvc>();

  get<DETECTOR>( m_location, updMgrSvc );

  auto sc = registerConditions( updMgrSvc );
  if ( !sc.isSuccess() ) { return sc; }

  // m_buffer will be filled and identifiers known
  updMgrSvc->update( this );

  if ( !m_dumpToFile.value() ) {
    auto svc = service( m_updaterName, true );
    if ( !svc ) {
      error() << "Failed get updater " << m_updaterName.value() << endmsg;
      return StatusCode::FAILURE;
    }
    auto* updater = dynamic_cast<Allen::NonEventData::IUpdater*>( svc.get() );
    if ( !updater ) {
      error() << "Failed cast updater " << m_updaterName.value() << " to Allen::NonEventData::IUpdater " << endmsg;
      return StatusCode::FAILURE;
    }
    for ( auto const& entry : m_buffer ) {
      auto const& id = std::get<0>( entry );
      updater->registerProducer( id, [this, id]() -> std::optional<std::vector<char>> {
        auto it = m_buffer.find( id );
        if ( it == m_buffer.end() ) {
          throw GaudiException{"Data for " + id + " not produced.", name(), StatusCode::FAILURE};
        } else {
          return it->second;
        }
      } );
    }
  }

  return sc;
}

template <typename DETECTOR>
StatusCode DumpGeometry<DETECTOR>::dump() {
  m_buffer.clear();
  try {
    auto result = dumpGeometry();
    for ( auto const& [data, filename, id] : result ) {
      if ( msgLevel( MSG::DEBUG ) ) {
        debug() << std::setw( 20 ) << id << ": " << std::setw( 7 ) << data.size() << " bytes." << endmsg;
      }
      if ( m_dumpToFile.value() ) {
        auto          name = outputDirectory() + "/" + filename + "_" + geometrySuffix() + ".bin";
        std::ofstream output{name, std::ios::out | std::ios::binary};
        output.write( data.data(), data.size() );
      } else {
        auto r = m_buffer.emplace( id, data );
        if ( !r.second ) {
          error() << "Failed to insert data for " << id << " in buffer." << endmsg;
          return StatusCode::FAILURE;
        }
      }
    }
    return StatusCode::SUCCESS;
  } catch ( const GaudiException& e ) {
    error() << e.message() << endmsg;
    return e.code();
  }
}

template <typename DETECTOR>
std::string DumpGeometry<DETECTOR>::geometrySuffix() const {
  auto sit = m_tags.find( "SIMCOND" );
  auto dit = m_tags.find( "DDDB" );
  auto cit = m_tags.find( "LHCBCOND" );
  if ( dit == end( m_tags ) ) {
    return "UNKOWN";
  } else if ( sit != end( m_tags ) ) {
    return dit->second + "_" + sit->second;
  } else {
    return dit->second + "_" + cit->second;
  }
}

#endif // DUMPGEOMETRY_H
