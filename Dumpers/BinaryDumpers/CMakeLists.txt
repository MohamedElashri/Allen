###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
################################################################################
# Package: BinaryDumpers
################################################################################

gaudi_add_library(BinaryDumpers
                  SOURCES
                    src/lib/TestUTBoards.cpp
                    src/lib/Utils.cpp
                  LINK PUBLIC
                    NonEventDataHeaders
                    Gear
                    AllenCommon
                    HostCommon
                    EventModel
                    AllenRuntime
                    AllenLib
                    Gaudi::GaudiKernel
                    LHCb::DAQEventLib
                    LHCb::FTDAQLib
                    LHCb::FTDetLib
                    LHCb::LHCbDetLib
                    LHCb::MagnetLib
                    LHCb::MuonDAQLib
                    LHCb::RecEvent
                    LHCb::RichFutureDAQLib
                    LHCb::RichFutureKernel
                    )

gaudi_add_module(BinaryDumpersModule
                 SOURCES
                   src/ODINProducer.cpp
                   src/AllenUpdater.cpp
                   src/DumpBeamline.cpp
                   src/DumpCrossingAngles.cpp
                   src/DumpCaloGeometry.cpp
                   src/DumpForwardTracks.cpp
                   src/DumpFTGeometry.cpp
                   src/DumpFTHits.cpp
                   src/DumpMagneticField.cpp
                   src/DumpMuonCommonHits.cpp
                   src/DumpMuonCoords.cpp
                   src/DumpMuonGeometry.cpp
                   src/DumpMuonTable.cpp
                   src/DumpRawBanks.cpp
                   src/DumpUTGeometry.cpp
                   src/DumpUTHits.cpp
                   src/DumpUTLookupTables.cpp
                   src/DumpVPGeometry.cpp
                   src/DumpRichCableMapping.cpp
                   src/DumpRichPDMDBMapping.cpp
                   src/PVDumper.cpp
                   src/ProvideConstants.cpp
                   src/TestMuonTable.cpp
                   src/TransposeRawBanks.cpp
                 LINK
                   Rangev3::rangev3
                   TBB::tbb
                   Gaudi::GaudiAlgLib
                   LHCb::AssociatorsBase
                   LHCb::LHCbAlgsLib
                   LHCb::LinkerEvent
                   LHCb::MCEvent
                   LHCb::DAQEventLib
                   LHCb::RecEvent
                   LHCb::VPDetLib
                   LHCb::UTDetLib
                   LHCb::UTKernelLib
                   LHCb::CaloDetLib
                   LHCb::FTDetLib
                   LHCb::MuonDAQLib
                   Rec::PrKernel
                   yaml-cpp::yaml-cpp
                   BinaryDumpers)

gaudi_add_tests(QMTest)

pybind11_add_module(bank_mapping NO_EXTRAS src/lib/bindings.cpp)
target_link_libraries(bank_mapping
                      PRIVATE
                        AllenCommon
                        HostCommon
                      PUBLIC
                        pybind11::pybind11
                        ${Python_LIBRARIES})
install(TARGETS bank_mapping
        EXPORT
          Allen
        LIBRARY DESTINATION
          ${GAUDI_INSTALL_PYTHONDIR}/Allen)
