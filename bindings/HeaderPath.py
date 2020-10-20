###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import os
import inspect

# Dirty hack until we sort out the procedure for a runtime environment
script_path = os.path.abspath(inspect.stack()[0][1])
allen_dir = os.sep.join(script_path.split(os.sep)[:-2])
root_include = os.environ['ROOT_INCLUDE_PATH'].split(':')
if allen_dir not in root_include:
    os.environ['ROOT_INCLUDE_PATH'] = ':'.join(root_include + [allen_dir])
