from AllenCore.ConfigurationOptions import allen_configuration_options

from sys import modules
if allen_configuration_options.standalone:
    from AllenAlgorithms import allen_algorithms
    modules[__name__] = allen_algorithms
else:
    from PyConf.importers import AlgorithmImporter
    modules[__name__] = AlgorithmImporter(__file__, __name__)
