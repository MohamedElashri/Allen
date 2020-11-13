/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#ifndef ALLENCALOTOCALOCLUSTERS_H
#define ALLENCALOTOCALOCLUSTERS_H

// Gaudi
#include "GaudiAlg/Transformer.h"

// LHCb
#include "Event/Track.h"

// Allen
#include "HostBuffers.cuh"
#include "Logger.h"
#include "VeloConsolidated.cuh"
#include "CaloCluster.cuh"
#include "CaloConstants.cuh"
#include "Event/CaloCluster.h"
#include "Event/CaloPosition.h"


class AllenCaloToCaloClusters final
  : public Gaudi::Functional::Transformer<std::vector<LHCb::CaloCluster>(const HostBuffers&)> {
public:
  /// Standard constructor
  AllenCaloToCaloClusters(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  std::vector<LHCb::CaloCluster> operator()(const HostBuffers&) const override;

private:
  Gaudi::Property<float> m_EtCalo {this, "EtCalo", 400 * Gaudi::Units::MeV, "Default ET for Calo Clusters"};
};

#endif
