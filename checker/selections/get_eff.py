import ROOT
import numpy as np
from array import array
import argparse
from collections import OrderedDict
from sets import Set

# Final state PIDs
fs = [211, 321, 13, 11]

# Prompt signal PIDs
prompt_sigs = [23, 443]

# Displaced signal PIDs
disp_sigs = [531]


class Reader:
    def __init__(self, intree):
        self.ttree = intree
        self.ntuple = self.setup(self.ttree)

    def setup(self, ttree):
        branches = ttree.GetListOfBranches()
        nBranches = branches.GetEntries()
        ntuple = OrderedDict()
        for i in range(nBranches):
            branch = branches.At(i)
            name = branch.GetName()
            ntuple[name] = ROOT.vector('double')()
            ttree.SetBranchAddress(name, ntuple[name])
        return ntuple

    def var(self, vname, idx):
        return self.ntuple[vname][idx]

    def length(self, vname):
        return len(self.ntuple[vname])

    # See if the event has a reconstructible decay.
    def find_gen_decay(self):
        gen_keys = Set()
        rec_keys = Set()
        n = len(self.ntuple['gen_key'])
        sig_pt = -1
        sig_tau = -1
        sig_pid = 0
        # Collect idxs of signal decay products.
        # Assume one signal decay per event.
        for i in range(n):
            pid = abs(int(self.var('gen_pid', i)))
            key = int(self.var('gen_key', i))
            mom_key = int(self.var('gen_mom_key', i))
            decmom_pid = abs(self.var('gen_decmom_pid', i))
            decmom_key = self.var('gen_decmom_key', i)
            decmom_pt = self.var('gen_decmom_pt', i)
            decmom_tau = self.var('gen_decmom_tau', i)
            # Displaced signals.
            if decmom_pid in disp_sigs:
                sig_pid = decmom_pid
                sig_pt = decmom_pt
                sig_tau = decmom_tau
                if decmom_tau < 0.0002 or decmom_pt < 2000:
                    return (-1., -1., -1., Set())
                pt = self.var('gen_pt', i)
                eta = self.var('gen_eta', i)
                long = int(self.var('gen_long', i))
                mom_pid = -1
                mom_pt = -1.
                mom_eta = -1.
                mom_long = -1
                for j in range(n):
                    if int(self.var('gen_key', j)) == mom_key:
                        mom_pid = abs(int(self.var('gen_pid', j)))
                        mom_pt = self.var('gen_pt', j)
                        mom_eta = self.var('gen_eta', j)
                        mom_long = int(self.var('gen_long', j))
                        break
                if pid in fs:
                    # Mom is not in final state.
                    if mom_pid not in fs:
                        gen_keys.add(key)
                        if pt > 200 and eta > 2 and eta < 5 and long == 1:
                            rec_keys.add(key)
                    # Mom is a FS particle but isn't long.
                    elif mom_long != 1:
                        gen_keys.add(key)
                        if pt > 200 and eta > 2 and eta < 5 and long == 1:
                            rec_keys.add(key)
                    # Mom is a FS particle and is long.
                    elif mom_long == 1:
                        gen_keys.add(mom_key)
                        if mom_pt > 200 and mom_eta > 2 and mom_eta < 5:
                            rec_keys.add(mom_key)
            # Prompt signals.
            if decmom_pid in prompt_sigs:
                sig_pt = decmom_pt
                sig_tau = decmom_tau
                pt = self.var('gen_pt', i)
                eta = self.var('gen_eta', i)
                long = int(self.var('gen_long', i))
                mom_pid = -1
                mom_pt = -1.
                mom_eta = -1.
                mom_long = -1
                for j in range(n):
                    if int(self.var('gen_key', j)) == mom_key:
                        mom_pid = abs(int(self.var('gen_pid', j)))
                        mom_pt = self.var('gen_pt', j)
                        mom_eta = self.var('gen_eta', j)
                        mom_long = int(self.var('gen_long', j))
                        break
                if pid in fs:
                    # Mom is not in final state.
                    if mom_pid not in fs:
                        gen_keys.add(key)
                        if pt > 200 and eta > 2 and eta < 5 and long == 1:
                            rec_keys.add(key)
                    # Mom is a FS particle but isn't long.
                    elif mom_long != 1:
                        gen_keys.add(key)
                        if pt > 200 and eta > 2 and eta < 5 and long == 1:
                            rec_keys.add(key)
                    # Mom is a FS particle and is long.
                    elif mom_long == 1:
                        gen_keys.add(mom_key)
                        if mom_pt > 200 and mom_eta > 2 and mom_eta < 5:
                            rec_keys.add(mom_key)
        if len(gen_keys) == 0: return (-1., -1., -1., Set())
        elif gen_keys != rec_keys: return (0., sig_pt, sig_tau, Set())
        else: return (sig_pid, sig_pt, sig_tau, gen_keys)

    # See if a reconstructed candidate comes from a generated signal.
    def tos(self, idxs, gen_keys):
        for idx in idxs:
            igen = int(self.var('trk_idx_gen', idx))
            if igen < 0: return False
            key = self.var('gen_key', igen)
            if key not in gen_keys: return False
        return True


def calculate_eff(fname):
    tfile = ROOT.TFile(fname)
    ttree = tfile.Get('eff_tree')
    reader = Reader(ttree)
    sigs = []
    svs = []
    trks = []
    print 'Number of entries: {}'.format(ttree.GetEntries())
    for i in range(ttree.GetEntries()):
        ttree.GetEntry(i)
        # Get reconstructible signals.
        pid, pt, tau, keys = reader.find_gen_decay()
        if len(keys) == 0: continue
        sigs.append((pid, keys, reader.var('event_pass_gec', 0)))
        # Get SVs that pass the 2-track line.
        evt_svs = []
        for isv in range(reader.length('sv_sumpt')):
            idxs = [
                int(reader.var('sv_idx_trk1', isv)),
                int(reader.var('sv_idx_trk2', isv))
            ]
            evt_svs.append({
                'from_signal': reader.tos(idxs, keys),
                'selections': {
                    'two_track': reader.var('sv_pass_two_track', isv),
                    'disp_dimuon': reader.var('sv_pass_disp_dimuon', isv),
                    'high_mass_dimuon': reader.var('sv_pass_high_mass_dimuon',
                                                   isv)
                }
            })
        svs.append(evt_svs)
        evt_trks = []
        # Get tracks passing rectangular 1-track cut.
        for itrk in range(reader.length('trk_p')):
            idxs = [itrk]
            evt_trks.append({
                'from_signal': reader.tos(idxs, keys),
                'selections': {
                    'one_track': reader.var('trk_pass_one_track', itrk),
                    'single_muon': reader.var('trk_pass_single_muon', itrk)
                }
            })
        trks.append(evt_trks)
    return sigs, svs, trks


if __name__ == '__main__':
    fname = '../../output/SelCheckerTuple.root'
    sigs, svs, trks = calculate_eff(fname)
    counters = OrderedDict([('two_track', 0), ('disp_dimuon', 0),
                            ('high_mass_dimuon', 0), ('one_track', 0),
                            ('single_muon', 0), ('global', 0)])
    tos_counters = OrderedDict([('two_track', 0), ('disp_dimuon', 0),
                                ('high_mass_dimuon', 0), ('one_track', 0),
                                ('single_muon', 0), ('global', 0)])
    nsig = len(sigs)
    nsig_gec = 0
    for sig, evt_svs, evt_trks in zip(sigs, svs, trks):
        if int(sig[2]) == 1: nsig_gec += 1
        found = {
            'two_track': False,
            'disp_dimuon': False,
            'high_mass_dimuon': False,
            'one_track': False,
            'single_muon': False
        }
        found_tos = {
            'two_track': False,
            'disp_dimuon': False,
            'high_mass_dimuon': False,
            'one_track': False,
            'single_muon': False
        }
        for sv in evt_svs:
            for line, val in sv['selections'].items():
                if int(val) == 1:
                    if not found[line]:
                        found[line] = True
                        counters[line] += 1
                    if not found_tos[line] and sv['from_signal']:
                        found_tos[line] = True
                        tos_counters[line] += 1
        for trk in evt_trks:
            for line, val in trk['selections'].items():
                if int(val) == 1:
                    if not found[line]:
                        found[line] = True
                        counters[line] += 1
                    if not found_tos[line] and trk['from_signal']:
                        found_tos[line] = True
                        tos_counters[line] += 1
        for key, val in found.items():
            if val:
                counters['global'] += 1
                break
        for key, val in found_tos.items():
            if val:
                tos_counters['global'] += 1
                break

    print '======================================================================'
    print 'Efficiencies'
    print '======================================================================'
    print '------------------------------'
    print 'GEC'
    print '------------------------------'
    print('{:5} / {:5} = {:.2f}%'.format(nsig_gec, nsig,
                                         100. * nsig_gec / nsig))
    for line, val in counters.items():
        tos_val = tos_counters[line]
        print '------------------------------'
        print line
        print '------------------------------'
        print('TIS-OR-TOS: {:5} / {:5} = {:.2f}%'.format(
            val, nsig_gec, 100. * val / nsig_gec))
        print('TOS       : {:5} / {:5} = {:.2f}%'.format(
            tos_val, nsig_gec, 100. * tos_val / nsig_gec))
