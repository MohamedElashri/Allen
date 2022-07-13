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

    unsigned int getVersion() const { return m_version; }
    void setVersion(unsigned int version)
    {
      // std::cout << "I am inside SetVersion" << std::endl;
      m_version = version;
      // std::cout << "I am gouing outside SetVersion: m_version is now: " << m_version << std::endl;
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
    MuonGeometry(
      unsigned int stations[maxTell40Number],
      unsigned int activelinks[maxTell40Number][maxTell40PCINumber],
      unsigned int linkregion[maxTell40Number][maxTell40PCINumber][maxNumberLinks],
      unsigned int linkquarter[maxTell40Number][maxTell40PCINumber][maxNumberLinks],
      unsigned int tileintell40[maxTell40Number][maxTell40PCINumber][maxNumberLinks * ODEFrameSize])
    {
      for (unsigned int itell = 0; itell < maxTell40Number; itell++) {
        m_stationsTell40[itell] = stations[itell];
        for (unsigned int ipci = 0; ipci < maxTell40PCINumber; ipci++) {
          // auto flattenedPCIindex = itell * maxTell40PCINumber + ipci;
          m_activeLink[itell][ipci] = activelinks[itell][ipci]; // activelinks[ flattenedPCIindex ] ;
          for (unsigned int ilink = 0; ilink < maxNumberLinks; ilink++) {
            // auto flattenedLinkindex = flattenedPCIindex * maxNumberLinks + ilink;
            m_regionOfLink[itell][ipci][ilink] = linkregion[itell][ipci][ilink];   //[flattenedLinkindex];
            m_quarterOfLink[itell][ipci][ilink] = linkquarter[itell][ipci][ilink]; //[flattenedLinkindex];
            for (unsigned int ich = 0; ich < ODEFrameSize; ich++) {
              // auto flattenedchindex = flattenedLinkindex * ODEFrameSize + ich;
              m_tileinTell40[itell][ipci][ilink * ODEFrameSize + ich] =
                tileintell40[itell][ipci][ilink * ODEFrameSize + ich]; //[flattenedchindex];
            }
          }
        }
      }
    }

    __device__ inline unsigned int whichStationIsTell40(unsigned int tell40_num) const
    {
      assert(tell40_num <= maxTell40Number);
      return m_stationsTell40[tell40_num];
    }

    __device__ inline unsigned int NumberOfActiveLink(unsigned int tell40_num, unsigned int PCI_num) const
    {
      assert(tell40_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);

      return m_activeLink[tell40_num - 1][PCI_num];
    }

    __device__ inline unsigned int RegionOfLink(unsigned int tell40_num, unsigned int PCI_num, unsigned int link_num)
      const
    {
      assert(tell40_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);
      assert(link_num <= maxNumberLinks);

      return m_regionOfLink[tell40_num - 1][PCI_num][link_num];
    }

    __device__ inline unsigned int QuarterOfLink(unsigned int tell40_num, unsigned int PCI_num, unsigned int link_num)
      const
    {
      assert(tell40_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);
      assert(link_num <= maxNumberLinks);

      return m_quarterOfLink[tell40_num - 1][PCI_num][link_num];
    }

    __device__ inline unsigned int
    TileInTell40(unsigned int tell40_num, unsigned int PCI_num, unsigned int link_num, unsigned int ch_num) const
    {
      assert(tell40_num <= maxTell40Number);
      assert(PCI_num <= maxTell40PCINumber);
      assert(link_num <= maxNumberLinks);

      return m_tileinTell40[tell40_num - 1][PCI_num][link_num * ODEFrameSize + ch_num];
    }

    /// IS THERE A BETTER PLACE FOR THIS?
    __device__ unsigned int get_number_of_readout_fibers(
      gsl::span<const uint8_t> span_banks,
      unsigned int active_links,
      unsigned int* map_connected_fibers)
    {

      unsigned int number_of_readout_fibers;

      if (!((span_banks[0] & 0x20) >> 5)) {
        for (unsigned int i = 0; i < active_links; i++) {
          map_connected_fibers[i] = i;
        }
        number_of_readout_fibers = active_links;
      }
      else {
        auto range_fiber = span_banks.subspan(1, 3);
        bool align_vector[24] = {};
        unsigned int readout_fibers = 0;
        for (int i = 0; i < 8; i++) {
          if ((range_fiber[0] >> i) & 0x1) {
            align_vector[16 + i] = true;
            readout_fibers++;
          }
          if ((range_fiber[1] >> i) & 0x1) {
            align_vector[8 + i] = true;
            readout_fibers++;
          }
          if ((range_fiber[2] >> i) & 0x1) {
            align_vector[i] = true;
            readout_fibers++;
          }
        }

        unsigned int fib_counter = 0;
        for (unsigned int i = 0; i < active_links; i++) {
          if (align_vector[i]) {
            map_connected_fibers[fib_counter] = i;
            fib_counter++;
          }
        }
        number_of_readout_fibers = readout_fibers;
      }
      return number_of_readout_fibers;
    }

  private:
    unsigned int m_version;
  };
} // namespace Muon
