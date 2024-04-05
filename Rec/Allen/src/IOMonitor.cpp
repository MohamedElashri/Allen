/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <GaudiKernel/Service.h>

namespace Allen {
  class IOMonitor : public Service {

    using Service::Service;
  };
} // namespace Allen

DECLARE_COMPONENT_WITH_ID(Allen::IOMonitor, "AllenIOMon")
