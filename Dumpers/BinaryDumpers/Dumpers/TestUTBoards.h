/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>
#include <vector>

/**
 * @brief      Class to test reading UT boards non-event data
 */
struct UTBoards {
  UTBoards(std::vector<char> data);

  uint32_t number_of_boards;
  uint32_t number_of_channels;
  uint32_t* stripsPerHybrids;
  uint32_t* stations;
  uint32_t* layers;
  uint32_t* detRegions;
  uint32_t* sectors;
  uint32_t* chanIDs;

private:
  std::vector<char> m_data;
};

UTBoards readBoards(std::string const& filename);
