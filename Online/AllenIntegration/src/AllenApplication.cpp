#include <dlfcn.h>

#include <iostream>
#include <chrono>
#include <thread>
#include <cmath>
#include <regex>

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

#ifdef HAVE_MPI
#include <MPIConfig.h>
#endif

#include "AllenConfiguration.h"
#include "AllenApplication.h"

namespace {
  using namespace std::string_literals;

  std::string resolveEnvVars(std::string s) {
    std::regex envExpr{"\\$\\{([A-Za-z0-9_]+)\\}"};
    std::smatch m;
    while(std::regex_search(s, m, envExpr)) {
      std::string rep;
      System::getEnv(m[1].str(), rep);
      s = s.replace(m[1].first - 2, m[1].second + 1, rep);
    }
    return s;
  }
}

/// Factory instantiation
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
  if (m_handle) {
    dlclose(m_handle);
  }
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
  if ( ret != Online::ONLINE_OK ) return ret;

  // dlopen libAllenLib
  m_handle = dlopen("libAllenLib.so", RTLD_LAZY);
  if (!m_handle) {
    m_logger->error("Failed to dlopen libAllenLib");
    return Online::ONLINE_ERROR;
  }

  // reset errors
  dlerror();
  // load the symbol
  m_allenFun = (allen_t) dlsym(m_handle, "allen");
  const char *dlsym_error = dlerror();
  if (dlsym_error) {
    m_logger->error("Failed to get 'allen' from libAllenLib");
    dlclose(m_handle);
    return Online::ONLINE_ERROR;
  }

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

  auto config = sloc->service("AllenConfiguration/AllenConfiguration").as<AllenConfiguration>();
  if (!config.get()) {
    m_logger->throwError("Failed to retrieve AllenConfiguration.");
    return Online::ONLINE_ERROR;
  }
  m_allenConfig = config.get();

  m_zmqSvc = sloc->service<IZeroMQSvc>("ZeroMQSvc");
  if (!m_zmqSvc) {
    m_logger->error("Failed to retrieve IZeroMQSvc.");
    return Online::ONLINE_ERROR;
  }

  SmartIF<IService> updater = sloc->service<IService>("AllenUpdater");
  if (!updater.get()) {
    m_logger->error("Failed to retrieve AllenUpdater.");
    return Online::ONLINE_ERROR;
  }
  m_updater = dynamic_cast<Allen::NonEventData::IUpdater*>(updater.get());
  if (updater == nullptr) {
    m_logger->error("Failed to cast AllenUpdater");
    return Online::ONLINE_ERROR;
  }

  if (m_allenConfig->withMPI.value()) {
    auto success = initMPI();
    if (!success) {
      m_logger->error("Failed to initialize MPI");
      return Online::ONLINE_ERROR;
    }
  }

  m_allenControl = m_zmqSvc->socket(zmq::PAIR);
  m_allenControl->bind(m_controlConnection.c_str());

  m_allenThread = std::thread{&AllenApplication::allenLoop, this};

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


bool AllenApplication::initMPI() {
#ifdef HAVE_MPI
  // MPI initialization
  auto len = name().length();
  int provided = 0;
  m_mpiArgv = new char*[1];
  m_mpiArgv[0] = new char[len];
  ::strncpy(m_mpiArgv[0], name().c_str(), len);
  MPI_Init_thread(&m_mpiArgc, &m_mpiArgv, MPI_THREAD_MULTIPLE, &provided);
  if (provided != MPI_THREAD_MULTIPLE) {
    m_logger->error("Failed to initialize MPI multi thread support.");
    return false;
  }

  // Communication size
  int comm_size = 0;
  MPI_Comm_size(MPI_COMM_WORLD, &comm_size);
  if (comm_size > MPI::comm_size) {
    std::string e = "This program requires at most "s + std::to_string(MPI::comm_size) + " processes.";
    m_logger->error(e.c_str());
    return false;
  }

  // MPI: Who am I?
  MPI_Comm_rank(MPI_COMM_WORLD, &m_rank);

  if (m_rank != MPI::receiver) {
    m_logger->error("AllenApplication can only function as MPI receiver.");
    return false;
  } else {
    return true;
  }
#else
  m_logger->error("MPI requested, but Allen was not built with MPI support.");
  return false;
#endif
}

void AllenApplication::allenLoop() {

  auto json = resolveEnvVars(m_allenConfig->json);

  //--events-per-slice 1000 --non-stop 1 --with-mpi $1:1 -c 0 -v 3 -t 8 -s 18 --output-file tcp://192.168.1.101:35000 --device 23:00.0
  std::map<std::string, std::string> allen_options = {{"events-per-slice", std::to_string(m_allenConfig->eps.value())},
                                                      {"non-stop", std::to_string(m_allenConfig->nonStop.value())},
                                                      {"c", std::to_string(m_allenConfig->check.value())},
                                                      {"v", std::to_string(6 - m_config->outputLevel())},
                                                      {"t", std::to_string(m_allenConfig->nThreads.value())},
                                                      {"configuration", json},
                                                      {"device", m_allenConfig->device.value()}};

  if (!m_allenConfig->output.value().empty()) {
    allen_options["output-file"] = m_allenConfig->output.value();
  }

  if (m_allenConfig->nSlices.value() != 0) {
    allen_options["s"] = std::to_string(m_allenConfig->nSlices.value());
  }

  if (m_allenConfig->withMPI.value() == true) {
    if (!m_allenConfig->receivers.value().empty()) {
      allen_options["with-mpi"] = m_allenConfig->receivers.value();
    } else {
      allen_options["with-mpi"] = "1";
    }
  }

  m_allenFun(allen_options, m_updater, m_zmqSvc.get(), m_controlConnection);

}
