from collections import defaultdict


def efficiencyHistoDict():
    basedict = {
        "eta": {},
        "p": {},
        "pt": {},
        "phi": {},
        "nPV": {},
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

    basedict["docaz"]["xTitle"] = "docaz"
    basedict["docaz"]["variable"] = "docaz"
    basedict["docaz"]["title"] = "docaz"

    return basedict


def ghostHistoDict():
    basedict = {"eta": {}, "nPV": {}}

    basedict["eta"]["xTitle"] = "#eta"
    basedict["eta"]["variable"] = "eta"

    basedict["nPV"]["xTitle"] = "# of PVs"
    basedict["nPV"]["variable"] = "nPV"

    return basedict


def getCuts():
    basedict = {"Velo": {}, "Upstream": {}, "Forward": {}}

    # basedict["Forward"] = [
    #     "Long_eta25", "LongFromB_eta25"
    # ]

    basedict["Velo"] = [
        "VeloTracks", "VeloTracks_eta25", "LongFromB_eta25", "LongFromD_eta25",
        "LongStrange_eta25"
    ]
    basedict["Upstream"] = [
        "VeloUTTracks_eta25", "LongFromB_eta25", "LongFromD_eta25",
        "LongStrange_eta25"
    ]
    basedict["Forward"] = [
        "Long_eta25", "LongFromB_eta25", "LongFromD_eta25", "LongStrange_eta25"
    ]

    return basedict


def categoriesDict():
    basedict = defaultdict(lambda: defaultdict(dict))

    basedict["Velo"]["VeloTracks"]["title"] = "Velo"
    basedict["Velo"]["VeloTracks_eta25"]["title"] = "Velo, 2 < eta < 5"
    basedict["Velo"]["LongFromB_eta25"]["title"] = "Long from B, 2 < eta < 5"
    basedict["Velo"]["LongFromD_eta25"]["title"] = "Long from D, 2 < eta < 5"
    basedict["Velo"]["LongStrange_eta25"][
        "title"] = "Long strange, 2 < eta < 5"
    basedict["Velo"]["VeloTracks"]["plotElectrons"] = True
    basedict["Velo"]["VeloTracks_eta25"]["plotElectrons"] = True
    basedict["Velo"]["LongFromB_eta25"]["plotElectrons"] = False
    basedict["Velo"]["LongFromD_eta25"]["plotElectrons"] = True
    basedict["Velo"]["LongStrange_eta25"]["plotElectrons"] = True

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

    basedict["Forward"]["Long_eta25"]["title"] = "Long, 2 < eta < 5"
    basedict["Forward"]["LongFromB_eta25"][
        "title"] = "Long from B, 2 < eta < 5"
    basedict["Forward"]["LongFromD_eta25"][
        "title"] = "Long from D, 2 < eta < 5"
    basedict["Forward"]["LongStrange_eta25"][
        "title"] = "Long strange, 2 < eta < 5"
    basedict["Forward"]["Long_eta25"]["plotElectrons"] = True
    basedict["Forward"]["LongFromB_eta25"]["plotElectrons"] = False
    basedict["Forward"]["LongFromD_eta25"]["plotElectrons"] = True
    basedict["Forward"]["LongStrange_eta25"]["plotElectrons"] = True

    return basedict
