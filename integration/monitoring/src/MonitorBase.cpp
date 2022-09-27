/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
