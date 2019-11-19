from collections import defaultdict

def pvEfficiencyHistoDict():
    basedict = {
        "z": {},
        "mult": {},
    }

    basedict["z"]["xTitle"] = "z [mm]"
    basedict["z"]["title"] = "z"

    basedict["mult"]["xTitle"] = "track multiplicity of MC PV"
    basedict["mult"]["title"] = "multiplicity"

    return basedict
