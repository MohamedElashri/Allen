###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from PyConf.application import ApplicationOptions, configure_input, configure
from PyConf.application import default_raw_event, default_raw_banks, configured_ann_svc, make_odin
from PyConf.control_flow import CompositeNode, NodeLogic
from PyConf.Algorithms import (HltSelReportsDecoder, HltDecReportsDecoder,
                               HltDecReportsMonitor, HltRoutingBitsMonitor)
from Configurables import ApplicationMgr


def make_selreports():
    return HltSelReportsDecoder(
        RawBanks=default_raw_banks("HltSelReports"),
        DecReports=default_raw_banks("HltDecReports"),
        SourceID='Hlt1',
        DecoderMapping="TCKANNSvc").OutputHltSelReportsLocation


def make_decreports():
    return HltDecReportsDecoder(
        RawBanks=default_raw_banks("HltDecReports"),
        SourceID='Hlt1',
        DecoderMapping="TCKANNSvc").OutputHltDecReportsLocation


def monitor(dec_reports):
    dr_monitor = HltDecReportsMonitor(
        name="HltDecReportsMonitor", Input=dec_reports)
    rb_monitor = HltRoutingBitsMonitor(
        name="HltRoutingBitsMonitor",
        RawBanks=default_raw_banks("HltRoutingBits"),
        ODIN=make_odin())
    return [dr_monitor, rb_monitor]


options = ApplicationOptions(_enabled=False)
options.histo_file = 'large_event_passthrough.root'
config = configure_input(options)

mgr = ApplicationMgr()
mgr.ExtSvc += [configured_ann_svc('TCKANNSvc')]

dec_reports = make_decreports()
sel_reports = make_selreports()
monitors = monitor(dec_reports)

cf_node = CompositeNode(
    "hlt1_decoding",
    [r.producer for r in (dec_reports, sel_reports)] + monitors,
    combine_logic=NodeLogic.LAZY_AND,
    force_order=True)

config.update(configure(options, cf_node))
