###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from collections import defaultdict


def efficiencyHistoDict():
    basedict = {
        "eta": {},
        "p": {},
        "pt": {},
        "phi": {},
        "nPV": {},
        "nSciFiHits": {},
        "docaz": {}
    }

    basedict["eta"]["xTitle"] = "#eta"
    basedict["eta"]["variable"] = "Eta"
    basedict["eta"]["title"] = "#eta"

    basedict["p"]["xTitle"] = "p [MeV]"
    basedict["p"]["variable"] = "P"
    basedict["p"]["title"] = "p"

    basedict["pt"]["xTitle"] = "p_{T} [MeV]"
    basedict["pt"]["variable"] = "Pt"
    basedict["pt"]["title"] = "p_{T}"

    basedict["phi"]["xTitle"] = "#phi [rad]"
    basedict["phi"]["variable"] = "Phi"
    basedict["phi"]["title"] = "#phi"

    basedict["nPV"]["xTitle"] = "# of PVs"
    basedict["nPV"]["variable"] = "nPV"
    basedict["nPV"]["title"] = "# of PVs"

    basedict["nSciFiHits"]["xTitle"] = "# of SciFi hits"
    basedict["nSciFiHits"]["variable"] = "nSciFiHits"
    basedict["nSciFiHits"]["title"] = "# of SciFi hits"

    basedict["docaz"]["xTitle"] = "docaz"
    basedict["docaz"]["variable"] = "docaz"
    basedict["docaz"]["title"] = "docaz"

    return basedict


def ghostHistoDict():
    basedict = {"eta": {}, "nPV": {}, "nSciFiHits": {}}

    basedict["eta"]["xTitle"] = "#eta"
    basedict["eta"]["variable"] = "eta"

    basedict["nPV"]["xTitle"] = "# of PVs"
    basedict["nPV"]["variable"] = "nPV"

    basedict["nSciFiHits"]["xTitle"] = "# of SciFi hits"
    basedict["nSciFiHits"]["variable"] = "nSciFiHits"

    return basedict


def getCuts():
    basedict = {
        "velo_validator": {},
        "Upstream": {},
        "long_validator": {},
        "seed_validator": {},
        "seed_xz_validator": {}
    }

    basedict["velo_validator"] = [
        "VeloTracks", "VeloTracks_eta25", "LongFromB_eta25", "LongFromD_eta25",
        "LongStrange_eta25"
    ]
    basedict["Upstream"] = [
        "VeloUTTracks_eta25", "LongFromB_eta25", "LongFromD_eta25",
        "LongStrange_eta25"
    ]
    basedict["long_validator"] = [
        "Long_eta25", "LongFromB_eta25", "LongFromD_eta25", "LongStrange_eta25"
    ]

    basedict["seed_validator"] = ["Long_eta25"]

    basedict["seed_xz_validator"] = ["Long_eta25"]

    return basedict


def categoriesDict():
    basedict = defaultdict(lambda: defaultdict(dict))

    basedict["velo_validator"]["VeloTracks"]["title"] = "Velo"
    basedict["velo_validator"]["VeloTracks_eta25"][
        "title"] = "Velo, 2 < eta < 5"
    basedict["velo_validator"]["LongFromB_eta25"][
        "title"] = "Long from B, 2 < eta < 5"
    basedict["velo_validator"]["LongFromD_eta25"][
        "title"] = "Long from D, 2 < eta < 5"
    basedict["velo_validator"]["LongStrange_eta25"][
        "title"] = "Long strange, 2 < eta < 5"
    basedict["velo_validator"]["VeloTracks"]["plotElectrons"] = True
    basedict["velo_validator"]["VeloTracks_eta25"]["plotElectrons"] = True
    basedict["velo_validator"]["LongFromB_eta25"]["plotElectrons"] = False
    basedict["velo_validator"]["LongFromD_eta25"]["plotElectrons"] = True
    basedict["velo_validator"]["LongStrange_eta25"]["plotElectrons"] = True

    basedict["Upstream"]["VeloUTTracks_eta25"]["title"] = "veloUT, 2 < eta < 5"
    basedict["Upstream"]["LongFromB_eta25"][
        "title"] = "Long from B, 2 < eta < 5"
    basedict["Upstream"]["LongFromD_eta25"][
        "title"] = "Long from D, 2 < eta < 5"
    basedict["Upstream"]["LongStrange_eta25"][
        "title"] = "Long strange, 2 < eta < 5"
    basedict["Upstream"]["VeloUTTracks_eta25"]["plotElectrons"] = True
    basedict["Upstream"]["LongFromB_eta25"]["plotElectrons"] = False
    basedict["Upstream"]["LongFromD_eta25"]["plotElectrons"] = True
    basedict["Upstream"]["LongStrange_eta25"]["plotElectrons"] = True

    basedict["long_validator"]["Long_eta25"]["title"] = "Long, 2 < eta < 5"
    basedict["long_validator"]["LongFromB_eta25"][
        "title"] = "Long from B, 2 < eta < 5"
    basedict["long_validator"]["LongFromD_eta25"][
        "title"] = "Long from D, 2 < eta < 5"
    basedict["long_validator"]["LongStrange_eta25"][
        "title"] = "Long strange, 2 < eta < 5"
    basedict["long_validator"]["Long_eta25"]["plotElectrons"] = False
    basedict["long_validator"]["LongFromB_eta25"]["plotElectrons"] = False
    basedict["long_validator"]["LongFromD_eta25"]["plotElectrons"] = True
    basedict["long_validator"]["LongStrange_eta25"]["plotElectrons"] = True

    basedict["seed_validator"]["Long_eta25"]["title"] = "Long, 2 < eta < 5"
    basedict["seed_validator"]["Long_eta25"]["plotElectrons"] = False

    basedict["seed_xz_validator"]["Long_eta25"]["title"] = "Long, 2 < eta < 5"
    basedict["seed_xz_validator"]["Long_eta25"]["plotElectrons"] = False

    return basedict
