from AllenCore.configuration_options import allen_configuration_options

from sys import modules
if allen_configuration_options.standalone:
    from AllenAlgorithms import allen_standalone_algorithms
    modules[__name__] = allen_standalone_algorithms
else:
    from PyConf.importers import AlgorithmImporter
    modules[__name__] = AlgorithmImporter(__file__, __name__)
