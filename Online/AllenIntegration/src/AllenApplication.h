#include <dlfcn.h>

#include <iostream>
#include <chrono>
#include <cmath>

#include <GaudiKernel/IJobOptionsSvc.h>
#include <GaudiKernel/IMessageSvc.h>
#include <GaudiKernel/IAppMgrUI.h>
#include <GaudiKernel/IProperty.h>
#include <GaudiKernel/ISvcLocator.h>
#include <GaudiKernel/AppReturnCode.h>
#include <GaudiKernel/Property.h>
#include <GaudiKernel/SmartIF.h>
#include <GaudiKernel/IMonitorSvc.h>
#include <CPP/Event.h>
#include <RTL/strdef.h>
#include <RTL/rtl.h>
#include <dis.hxx>

#include <GaudiOnline/OnlineApplication.h>

#include <Allen.h>

#include "AllenConfiguration.h"

class AllenApplication : public Online::OnlineApplication  {
  public:

  /// Structurte containing all monitoring items
  struct monitor_t   {
    long mepsIn          = 0;
    long mepsDone        = 0;
    long eventsOut       = 0;
    monitor_t() = default;
    virtual ~monitor_t() = default;
    void reset();
  } m_monitor;

  // Specialized constructor
  AllenApplication(Options opts);
  // Default destructor
  virtual ~AllenApplication();

  /// Cancel the application: Cancel IO request/Event loop
  int cancel()  override;

  /// Internal: Initialize the application            (NOT_READY  -> READY)
  int configureApplication()   override;
  /// Internal: Finalize the application              (READY      -> NOT_READY)
  int finalizeApplication()   override;

  /// Internal: Start the application                 (READY      -> RUNNING)
  int startApplication()   override;
  /// Stop the application                            (RUNNING    -> READY)
  int stop()    override;
  /// Pause the application                           (RUNNING    -> PAUSED)
  int pauseProcessing()   override;
  /// Continue the application                        (PAUSED -> RUNNING )
  int continueProcessing()    override;

  // Main function running the Allen event loop
  void allen_loop();

private:

  /// Reference to the monitoring service
  SmartIF<IMonitorSvc>        m_monSvc;

  /// Handles to helper service to properly name burst counters
  SmartIF<IService>           m_monMEPs;
  /// Handles to helper service to properly name event counters
  SmartIF<IService>           m_monEvents;

  Allen::NonEventData::IUpdater* m_updater = nullptr;
  AllenConfiguration const* m_allenConfig = nullptr;

  std::string m_controlConnection = "inproc://AllenApplicationControl";

  void* m_handle = nullptr;
  typedef int (*allen_t)(std::map<std::string, std::string>, Allen::NonEventData::IUpdater*, std::string_view);
  allen_t m_allen_fun = nullptr;

};
