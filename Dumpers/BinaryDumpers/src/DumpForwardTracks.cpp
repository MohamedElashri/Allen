/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <vector>

#include <boost/filesystem.hpp>

//#include "Event/RawEvent.h"
//#include "Event/VPLightCluster.h"

#include "DumpForwardTracks.h"
#include "Utils.h"

namespace fs = boost::filesystem;

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(DumpForwardTracks)

DumpForwardTracks::DumpForwardTracks(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(
    name,
    pSvcLocator,
    {KeyValue {"ODINLocation", LHCb::ODINLocation::Default},
     KeyValue {"ForwardTracksLocation", "Rec/Track/ForwardFast"}})
{}

StatusCode DumpForwardTracks::initialize()
{
  if (!DumpUtils::createDirectory(m_outputDirectory.value())) {
    error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
    return StatusCode::FAILURE;
  }
  return StatusCode::SUCCESS;
}

void DumpForwardTracks::operator()(const LHCb::ODIN& odin, const std::vector<LHCb::Event::v2::Track>& tracks) const
{

  /*Write LHCbIDs of forward tracks to binary file */
  DumpUtils::FileWriter outfile {m_outputDirectory.value() + "/" + std::to_string(odin.runNumber()) + "_" +
                                 std::to_string(odin.eventNumber()) + ".bin"};

  // first the number of tracks
  const uint32_t n_tracks = (int) (tracks.size());
  outfile.write(n_tracks);

  // then the tracks themselves
  for (const auto& track : tracks) {
    const float eta = track.pseudoRapidity();
    outfile.write(eta);
    const float p = track.p();
    outfile.write(p);
    const float pt = track.pt();
    outfile.write(pt);

    // first the number of IDs on this track
    const uint32_t n_IDs = track.nLHCbIDs();
    outfile.write(n_IDs);

    // then the IDs
    const auto ids = track.lhcbIDs();
    for (const auto& id : ids) {
      // const unsigned int id_int = id;
      outfile.write(id);
    }
  }
}
