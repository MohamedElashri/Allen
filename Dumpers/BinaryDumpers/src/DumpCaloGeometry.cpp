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
#include <array>
#include <fstream>
#include <iostream>
#include <tuple>
#include <vector>

#include "DumpCaloGeometry.h"
#include "Utils.h"

#define MIN(a, b) (a < b ? a : b)
#define MAX(a, b) (a > b ? a : b)
#define MAX_NEIGH 9
#define AREA_SIZE 64 * 64 // 4096

DECLARE_COMPONENT(DumpCaloGeometry)

namespace {
  const std::map<std::string, std::string> ids = {{"EcalDet", Allen::NonEventData::ECalGeometry::id},
                                                  {"HcalDet", Allen::NonEventData::HCalGeometry::id}};
  using namespace std::string_literals;
}

DumpUtils::Dumps DumpCaloGeometry::dumpGeometry() const
{

  // Detector and mat geometry
  const DeCalorimeter& det = detector();

  // SourceID to feCards: tell1ToCards for 0 - det.nTell1s   Returns tell1Param which has .feCards int vector.
  // Bank header code to card using cardCode() function which operates on CardParam which has card code and channels.
  // check codes in Python; check feCards to code if this is standard somehow.

  // 192 cards -> 192 codes.
  // Could maintain list of sourceID to number of cards and then use this to get index of code respective to sourceID.
  // Or use max size (which is 8 now, but should be considered a variable) and use this to find code index.
  // 
  // Idea: use code as index (technically code - min(codes) * 32). The 32 channels associated with this card
  // start at this index. Using the num we can further index these 32 channels.
  // Wasted space: 32 * 16 bits per missing card code 

  std::vector<int> cards{};
  std::vector<int> curCards{};
  // Get all card indices for every source ID.
  for (int i = 0; i < det.nTell1s(); i++) {
    curCards = det.tell1ToCards(i);
    cards.insert(cards.end(), curCards.begin(), curCards.end());
  }

  // Determine Minimum and maximum card Codes.
  int min = det.cardCode(cards.at(0)); // Initialize to any value within possibilities.
  int max = 0;
  int curCode;
  for (int card : cards) {
    curCode = det.cardCode(card);
    min = MIN(curCode, min);
    max = MAX(curCode, max);
  }

  // Initialize array to size (max - min) * 32.
  std::vector<uint16_t> allChannels(32 * (max - min + 1), 0);

  // For every card: index based on code and store all 32 channel CellIDs at that index.
  for (int card : cards) {
    int code = det.cardCode(card);
    int index = (code - min) * 32;
    auto channels = det.cardChannels(card);
    for (size_t i = 0; i < channels.size(); i++) {
      allChannels[index + i] = (uint16_t) channels.at(i).index();
    }
  }

  // Create neighbours per cellID.
  const CaloVector<CellParam>& params = det.cellParams();
  // Check if 'E'cal or 'H'cal
  uint levels = det.caloName()[0] == 'E' ? 3 : 2;
  std::vector<uint16_t> neighbors(levels * AREA_SIZE * MAX_NEIGH, 0);
  std::vector<double> xy(levels * AREA_SIZE * 2, 0);
  for (auto param : params) {
    auto cid = param.cellID();
    if(cid.area() >= levels) {
      continue;
    }
    auto ns = param.neighbors();
    for (size_t i = 0; i < ns.size(); i++) {
      // Use 4D indexing based on Area, row, column and neighbor index.
      neighbors[cid.index() * MAX_NEIGH + i] = (uint16_t) ns.at(i).index();
    }
    xy[cid.index() * 2] = param.x();
    xy[cid.index() * 2 + 1] = param.y();
  }



  // Write the neighbors offset, the xy offset, minimum card code, array of CellIDs,
  // the array of neighbors and the array of xy values.
  DumpUtils::Writer output {};
  output.write((uint32_t) (allChannels.size() * sizeof(uint16_t)));
  output.write((uint32_t) (allChannels.size() * sizeof(uint16_t) + neighbors.size() * sizeof(uint16_t)));
  output.write((uint16_t) min);
  for (uint16_t chan : allChannels) {
    output.write(chan);
  }
  
  for (uint16_t neigh : neighbors) {
    output.write(neigh);
  }

  for (double xory : xy) {
    output.write(xory);
  }


  auto id = ids.find(det.caloName());
  if (id == ids.end()) {
    throw GaudiException{"Cannot find "s + det.caloName(), name(), StatusCode::FAILURE};
  }
  return {{std::tuple {output.buffer(), det.caloName() + "_geometry", id->second}}};
}
