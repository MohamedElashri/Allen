/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "MonitorBase.h"
#include "ROOTHeaders.h"
#include "MonitorManager.h"

#include <ctime>

void MonitorBase::saveHistograms() const
{
  auto* dir = m_manager->directory();

  if (dir != nullptr) {
    for (auto& kv : m_histograms) {
      auto h = kv.second.get();
      dir->WriteTObject(h, h->GetName(), "overwrite");
    }
  }
}

unsigned MonitorBase::getWallTimeBin()
{
  if (m_offset <= 0) m_offset = time(0);

  return time(0) - m_offset;
}
