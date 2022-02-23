###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
################################################################################
# Package: BinaryDumpers
################################################################################


gaudi_add_library(BinaryDumpers
                  SOURCES
                    src/lib/TestUTBoards.cpp
                    src/lib/Utils.cpp
                  LINK PUBLIC
                    Gaudi::GaudiKernel
                    LHCb::DAQEventLib
                    LHCb::MuonDAQLib)

gaudi_add_module(BinaryDumpersModule
                 SOURCES
                   src/AllenUpdater.cpp
                   src/DumpBeamline.cpp
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
                   src/PVDumper.cpp
                   src/TestMuonTable.cpp
                   src/TransposeRawBanks.cpp
                 LINK
                   Rangev3::rangev3
                   Gaudi::GaudiAlgLib
                   LHCb::AssociatorsBase
                   LHCb::LinkerEvent
                   LHCb::MCEvent
                   LHCb::DAQEventLib
                   LHCb::DAQKernelLib
                   LHCb::VPDetLib
                   LHCb::UTDetLib
                   LHCb::UTKernelLib
                   LHCb::CaloDetLib
                   LHCb::FTDetLib
                   LHCb::MuonDAQLib
                   Rec::PrKernel
                   BinaryDumpers)

gaudi_add_tests(QMTest)
