from AllenCore.configuration_options import allen_configuration_options

from sys import modules
if allen_configuration_options.standalone:
    from AllenCore import allen_standalone_generator
    modules[__name__] = allen_standalone_generator
else:
    from AllenCore import gaudi_allen_generator
    modules[__name__] = gaudi_allen_generator
