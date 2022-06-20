/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <algorithm>

#include "MuonTileID.cuh"
#include "MuonDefinitions.cuh"

using namespace Muon::Constants;

namespace Muon {
  class MuonGeometry {
  public:
    MuonGeometry() {}

    unsigned int getVersion() const { return m_version;}
    void setVersion( unsigned int version) { 
      std::cout << "I am inside SetVersion" << std::endl;
      m_version = version;
      std::cout << "I am gouing outside SetVersion: m_version is now: " << m_version << std::endl;
      return;
    }

    ///////////////// getters for version2
    MuonGeometry(size_t* sizes, unsigned** tiles)
    {
      for (size_t i = 0; i < m_tiles_size; i++) {
        m_sizes[i] = sizes[i];
        m_tiles[i] = tiles[i];
      }
    }

    static constexpr size_t m_tiles_size = 10;
    unsigned* m_tiles[m_tiles_size];
    size_t m_sizes[m_tiles_size];

    __device__ inline unsigned int getADDInTell1(unsigned int Tell1_num, unsigned int ch) const
    {
      assert(Tell1_num <= m_tiles_size);
      assert(ch < m_sizes[Tell1_num]);

      return m_tiles[Tell1_num][ch];
    }

    ///////////////// getters for version3
    unsigned int m_stationsTell40[maxTell40Number];
    unsigned int m_activeLink[maxTell40Number][maxTell40PCINumber];
    unsigned int m_regionOfLink[maxTell40Number][maxTell40PCINumber][maxNumberLinks];
    unsigned int m_quarterOfLink[maxTell40Number][maxTell40PCINumber][maxNumberLinks];
    unsigned int m_tileinTell40[maxTell40Number][maxTell40PCINumber][maxNumberLinks * ODEFrameSize];

    ///////////////// version3 constructor
    MuonGeometry(unsigned int stations[maxTell40Number], 
		 unsigned int activelinks[maxTell40Number][maxTell40PCINumber], 
		 unsigned int linkregion[maxTell40Number][maxTell40PCINumber][maxNumberLinks], 
		 unsigned int linkquarter[maxTell40Number][maxTell40PCINumber][maxNumberLinks], 
		 unsigned int tileintell40[maxTell40Number][maxTell40PCINumber][maxNumberLinks * ODEFrameSize])
    {
      for ( unsigned int itell = 0; itell < maxTell40Number; itell++){
	m_stationsTell40[itell] = stations[itell];
	for ( unsigned int ipci = 0; ipci < maxTell40PCINumber; ipci++){
	  //auto flattenedPCIindex = itell * maxTell40PCINumber + ipci;
	  m_activeLink[itell][ipci] = activelinks[itell][ipci]; //activelinks[ flattenedPCIindex ] ;
	  for ( unsigned int ilink = 0; ilink < maxNumberLinks; ilink++){
	    //auto flattenedLinkindex = flattenedPCIindex * maxNumberLinks + ilink;
	    m_regionOfLink[itell][ipci][ilink] = linkregion[itell][ipci][ilink]; //[flattenedLinkindex];
	    m_quarterOfLink[itell][ipci][ilink] = linkquarter[itell][ipci][ilink]; //[flattenedLinkindex];
	    for ( unsigned int ich = 0; ich < ODEFrameSize; ich++ ) {
	      //auto flattenedchindex = flattenedLinkindex * ODEFrameSize + ich;
	      m_tileinTell40[itell][ipci][ilink * ODEFrameSize + ich] = tileintell40[itell][ipci][ilink * ODEFrameSize + ich]; //[flattenedchindex];
	    }
	  }
	}
      }
    }

    __device__ inline unsigned int whichStationIsTell40(unsigned int Tell1_num) const
    {
      assert(Tell1_num <= maxTell40Number);
      return m_stationsTell40[Tell1_num];
    }

    __device__ inline unsigned int NumberOfActiveLink(unsigned int Tell1_num, unsigned int PCI_num) const
    {
      assert(Tell1_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);

      return m_activeLink[Tell1_num -1][PCI_num];
    }

    __device__ inline unsigned int RegionOfLink(unsigned int Tell1_num, unsigned int PCI_num, unsigned int link_num) const
    {
      assert(Tell1_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);
      assert(link_num <= maxNumberLinks);      

      return m_regionOfLink[Tell1_num -1][PCI_num][link_num];
    }

    __device__ inline unsigned int QuarterOfLink(unsigned int Tell1_num, unsigned int PCI_num, unsigned int link_num) const
    {
      assert(Tell1_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);
      assert(link_num <= maxNumberLinks);      

      return m_quarterOfLink[Tell1_num - 1][PCI_num][link_num];
    }

    __device__ inline unsigned int TileInTell40(unsigned int Tell1_num, unsigned int PCI_num, unsigned int link_num, unsigned int ch_num) const
    {
      assert(Tell1_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);
      assert(link_num <= maxNumberLinks);      

      return m_tileinTell40[Tell1_num -1][PCI_num][link_num * ODEFrameSize + ch_num];
    }

  private:
    unsigned int m_version;
  };
} // namespace Muon
