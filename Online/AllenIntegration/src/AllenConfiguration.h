#pragma once

#include "GaudiKernel/Service.h"

class AllenConfiguration : public Service  {
  public:
    /// Retrieve interface ID
  static const InterfaceID& interfaceID() {
    // Declaration of the interface ID.
    static const InterfaceID iid("AllenConfiguration", 0, 0);
    return iid;
  }

  /// Query interfaces of Interface
  StatusCode queryInterface(const InterfaceID& riid, void** ppv);
  AllenConfiguration(std::string name, ISvcLocator* svcloc);

  ~AllenConfiguration();

  Gaudi::Property<int> eps{this, "EventsPerSlice", 1000};
  Gaudi::Property<bool> nonStop{this, "NonStop", true};
  Gaudi::Property<bool> withMPI{this, "MPI", true};
  Gaudi::Property<std::string> receivers{this, "Receivers", ""};
  Gaudi::Property<bool> check{this, "CheckMC", false};
  Gaudi::Property<unsigned int> nThreads{this, "NThreads", 8};
  Gaudi::Property<unsigned int> nSlices{this, "NSlices", 16};
  Gaudi::Property<std::string> output{this, "Output", ""};
  Gaudi::Property<std::string> device{this, "Device", "0"};
  Gaudi::Property<std::string> json{this, "JSON", "${ALLEN_PROJECT_ROOT}/configuration/constants/default.json"};

};
