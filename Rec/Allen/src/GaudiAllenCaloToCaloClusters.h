/*****************************************************************************\
* (c) Copyright 2008-2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <vector>

// Gaudi
#include "GaudiAlg/Transformer.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "Logger.h"
#include "VeloConsolidated.cuh"
#include "CaloCluster.cuh"
#include "Event/CaloClusters_v2.h"
#include "Detector/Calo/CaloCellID.h"
#include "GaudiKernel/Point3DTypes.h"

class GaudiAllenCaloToCaloClusters final
  : public Gaudi::Functional::Transformer<
      LHCb::Event::Calo::Clusters(const std::vector<unsigned>&, const std::vector<CaloCluster>&)> {
public:
  /// Standard constructor
  GaudiAllenCaloToCaloClusters(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  LHCb::Event::Calo::Clusters operator()(
    const std::vector<unsigned>& allen_ecal_cluster_offsets,
    const std::vector<CaloCluster>& allen_ecal_clusters) const override;

private:
  Gaudi::Property<float> m_EtCalo {this, "EtCalo", 400 * Gaudi::Units::MeV, "Default ET for Calo Clusters"};
};
