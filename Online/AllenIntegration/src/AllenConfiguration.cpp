#include "GaudiKernel/Service.h"
#include "AllenConfiguration.h"

DECLARE_COMPONENT( AllenConfiguration )

/// Query interfaces of Interface
StatusCode AllenConfiguration::queryInterface(const InterfaceID& riid, void** ppv)  {
  if ( AllenConfiguration::interfaceID().versionMatch(riid) )   {
    *ppv = this;
    addRef();
    return StatusCode::SUCCESS;
  }
  return Service::queryInterface(riid,ppv);
}

AllenConfiguration::AllenConfiguration(std::string name, ISvcLocator* svcloc)
  : Service(name, svcloc) {}

AllenConfiguration::~AllenConfiguration()
{

}
