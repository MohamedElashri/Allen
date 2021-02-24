add_library(EventModel INTERFACE)

target_include_directories(EventModel INTERFACE
  associate/include
  common/include
  calo/include
  muon/include
  SciFi/include
  selections/include
  UT/include
  velo/include
  kalman/include
  PV/include)
