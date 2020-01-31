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

/// C/C++ include files
#include <iostream>
#include <chrono>
#include <cmath>

#include <Allen.h>

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

};

DECLARE_COMPONENT( AllenApplication )

/// Reset counters at start
void AllenApplication::monitor_t::reset()   {
  mepsIn          = 0;
  eventsOut         = 0;
}

/// Specialized constructor
AllenApplication::AllenApplication(Options opts)
  : OnlineApplication(opts)
{
}

// Default destructor
AllenApplication::~AllenApplication()
{
}

/// Stop the application                             (RUNNING    -> READY)
int AllenApplication::stop()   {
  fireIncident("DAQ_CANCEL");

  return OnlineApplication::stop();
}

/// Cancel the application: Cancel IO request/Event loop
int AllenApplication::cancel()  {
  return 1;
}

/// Internal: Initialize the application            (NOT_READY  -> READY)
int AllenApplication::configureApplication()   {
  int ret = OnlineApplication::configureApplication();
  if ( ret == Online::ONLINE_OK )   {
    SmartIF<ISvcLocator> sloc = app.as<ISvcLocator>();

    if ( !m_config->monitorType.empty() )   {

      m_monMEPs.reset(new Service("MEPs", sloc));
      m_monEvents.reset(new Service("Events", sloc));

      m_monSvc = sloc->service<IMonitorSvc>(m_config->monitorType);
      if ( !m_monSvc.get() )  {
        m_logger->error("Cannot access monitoring service of type %s.",
                        m_config->monitorType.c_str());
        return Online::ONLINE_ERROR;
      }
      m_monSvc->declareInfo("IN",        m_monitor.mepsIn,
			    "Number of MEPs received for processing", m_monMEPs);
      m_monSvc->declareInfo("OUT",       m_monitor.mepsDone,
			    "Number of MEPs fully processed", m_monMEPs);
      m_monSvc->declareInfo("OUT",       m_monitor.eventsOut,
			    "Number of events fully output", m_monEvents);
    }
  }
  return ret;
}

/// Internal: Finalize the application              (READY      -> NOT_READY)
int AllenApplication::finalizeApplication()   {
  if ( m_monSvc.get() )  {
    m_monSvc->undeclareAll(m_monMEPs);
    m_monSvc->undeclareAll(m_monEvents);
    m_monSvc.reset();
  }
  m_monMEPs.reset();
  m_monEvents.reset();
  return OnlineApplication::finalizeApplication();
}

/// Internal: Start the application                 (READY      -> RUNNING)
int AllenApplication::startApplication()   {
  if (true) {
    return Online::ONLINE_OK;
  } else {
    return m_logger->error("+++ Inconsistent thread state! [FSM failure]");
  }
}

/// Pause the application                            (RUNNING    -> READY)
int AllenApplication::pauseProcessing()   {
  m_logger->debug("Pause the application.");
  return OnlineApplication::pauseProcessing();
}

/// Continue the application                        (PAUSED -> RUNNING )
int AllenApplication::continueProcessing()    {
  m_logger->debug("Resume application processing.");
  return OnlineApplication::continueProcessing();
}
