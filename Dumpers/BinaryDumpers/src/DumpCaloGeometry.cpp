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

#include <Kernel/CaloCellID.h>
#include <Kernel/CaloCellCode.h>
#include "DumpCaloGeometry.h"
#include "Utils.h"

DECLARE_COMPONENT(DumpCaloGeometry)

namespace {
  const std::map<std::string, std::string> ids = {{"EcalDet", Allen::NonEventData::ECalGeometry::id},
                                                  {"HcalDet", Allen::NonEventData::HCalGeometry::id}};
  using namespace std::string_literals;
  constexpr unsigned max_neighbors = 9;
} // namespace

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

  std::vector<int> cards {};
  // Get all card indices for every source ID.
  for (int i = 0; i < det.nTell1s(); i++) {
    auto tell1Cards = det.tell1ToCards(i);
    cards.insert(cards.end(), tell1Cards.begin(), tell1Cards.end());
  }

  // Determine offset and size of the global dense index;
  unsigned indexOffset = 0, indexSize = 0;
  namespace IndexDetails = LHCb::Calo::DenseIndex::details;
  unsigned int hcalOuterOffset =
    IndexDetails::Constants<LHCb::Calo::CellCode::Index::HcalCalo, IndexDetails::Area::Outer>::global_offset;
  if (det.caloName()[0] == 'E') {
    indexSize = hcalOuterOffset;
  }
  else {
    indexOffset = hcalOuterOffset;
    indexSize = LHCb::Calo::Index::max() - indexOffset;
  }

  // Determine Minimum and maximum card Codes.
  int min = det.cardCode(cards.at(0)); // Initialize to any value within possibilities.
  int max = 0;
  size_t max_channels = 0;
  int curCode = 0;
  for (int card : cards) {
    curCode = det.cardCode(card);
    min = std::min(curCode, min);
    max = std::max(curCode, max);
    max_channels = std::max(det.cardChannels(card).size(), max_channels);
  }

  // Initialize array to size (max - min) * 32.
  std::vector<uint16_t> allChannels(max_channels * (max - min + 1), 0);

  // For every card: index based on code and store all 32 channel CellIDs at that index.
  for (int card : cards) {
    int code = det.cardCode(card);
    int index = (code - min) * max_channels;
    auto channels = det.cardChannels(card);
    for (size_t i = 0; i < channels.size(); i++) {
      LHCb::Calo::Index const caloIndex {channels.at(i)};
      if (caloIndex) {
        allChannels[index + i] = static_cast<uint16_t>(caloIndex - indexOffset);
      }
      else {
        allChannels[index + i] = static_cast<uint16_t>(indexSize);
      }
    }
  }

  // Check if 'E'cal or 'H'cal
  std::vector<uint16_t> neighbors(indexSize * max_neighbors, 0);
  std::vector<float> xy(indexSize * 2, 0.f);
  std::vector<float> gain(indexSize, 0.f);
  // Create neighbours per cellID.
  for (auto const& param : det.cellParams()) {
    auto const caloIndex = LHCb::Calo::Index {param.cellID()};
    if (!caloIndex) {
      continue;
    }
    auto const idx = caloIndex - indexOffset;
    auto const& ns = param.neighbors();
    for (size_t i = 0; i < ns.size(); i++) {
      // Use 4D indexing based on Area, row, column and neighbor index.
      LHCb::Calo::Index const neighborIndex {ns.at(i)};
      if (neighborIndex) {
        neighbors[idx * max_neighbors + i] = static_cast<uint16_t>(neighborIndex - indexOffset);
      }
    }
    xy[idx * 2] = param.x();
    xy[idx * 2 + 1] = param.y();
    gain[idx] = det.cellGain(param.cellID());
  }

  // Get toLocalMatrix
  std::vector<float> toLocalMatrix_elements(12, 0.f);
  det.toLocalMatrix().GetComponents(toLocalMatrix_elements.begin(), toLocalMatrix_elements.end());

  // Get front, showermax and back planes a,b,c,d parameters (A plane in 3D is defined as a*x+b*y+c*z+d=0)
  std::vector<float> calo_planes {static_cast<float>(det.plane(CaloPlane::Front).A()),
                                  static_cast<float>(det.plane(CaloPlane::Front).B()),
                                  static_cast<float>(det.plane(CaloPlane::Front).C()),
                                  static_cast<float>(det.plane(CaloPlane::Front).D()),
                                  static_cast<float>(det.plane(CaloPlane::ShowerMax).A()),
                                  static_cast<float>(det.plane(CaloPlane::ShowerMax).B()),
                                  static_cast<float>(det.plane(CaloPlane::ShowerMax).C()),
                                  static_cast<float>(det.plane(CaloPlane::ShowerMax).D()),
                                  static_cast<float>(det.plane(CaloPlane::Back).A()),
                                  static_cast<float>(det.plane(CaloPlane::Back).B()),
                                  static_cast<float>(det.plane(CaloPlane::Back).C()),
                                  static_cast<float>(det.plane(CaloPlane::Back).D())};

  // Get Module size
  float module_size = static_cast<float>(det.cellSize(det.firstCellID(1)));

  // Get ranges of area in the global dense index
  std::vector<uint32_t> digits_ranges;
  if (det.caloName()[0] == 'E') {
    digits_ranges = {
      indexOffset,
      IndexDetails::Constants<LHCb::Calo::CellCode::Index::EcalCalo, IndexDetails::Area::Middle>::global_offset,
      IndexDetails::Constants<LHCb::Calo::CellCode::Index::EcalCalo, IndexDetails::Area::Inner>::global_offset,
      indexOffset + indexSize};
  }
  else {
    digits_ranges = {
      indexOffset,
      IndexDetails::Constants<LHCb::Calo::CellCode::Index::HcalCalo, IndexDetails::Area::Inner>::global_offset,
      indexOffset + indexSize};
  }

  // Write all the parameters to the geometry file
  DumpUtils::Writer output {};
  output.write(static_cast<uint32_t>(min));
  output.write(static_cast<uint32_t>(max_channels));
  output.write(static_cast<uint32_t>(indexSize));
  float pedestal = det.pedestalShift();
  output.write(pedestal);
  output.write(static_cast<uint32_t>(allChannels.size()));
  output.write(allChannels);
  output.write(static_cast<uint32_t>(neighbors.size()));
  output.write(neighbors);
  output.write(static_cast<uint32_t>(xy.size()));
  output.write(xy);
  output.write(static_cast<uint32_t>(gain.size()));
  output.write(gain);
  output.write(static_cast<uint32_t>(toLocalMatrix_elements.size()));
  output.write(toLocalMatrix_elements);
  output.write(static_cast<uint32_t>(calo_planes.size()));
  output.write(calo_planes);
  output.write(module_size);
  output.write(static_cast<uint32_t>(digits_ranges.size()));
  output.write(digits_ranges);

  auto id = ids.find(det.caloName());
  if (id == ids.end()) {
    throw GaudiException {"Cannot find "s + det.caloName(), name(), StatusCode::FAILURE};
  }

  if (det.caloName()[0] == 'E') {
    return {{std::tuple {output.buffer(), "ecal_geometry", id->second}}};
  }
  else {
    return {{std::tuple {output.buffer(), "hcal_geometry", id->second}}};
  }
}
