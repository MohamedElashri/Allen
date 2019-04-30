###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
import os
import inspect

# Dirty hack until we sort out the procedure for a runtime environment
script_path = os.path.abspath(inspect.stack()[0][1])
allen_dir = os.sep.join(script_path.split(os.sep)[:-2])
root_include = os.environ['ROOT_INCLUDE_PATH'].split(':')
if allen_dir not in root_include:
    os.environ['ROOT_INCLUDE_PATH'] = ':'.join(root_include + [allen_dir])
