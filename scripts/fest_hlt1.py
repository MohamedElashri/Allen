###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
import re
import os
import subprocess


def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    n = int(len(l) / n + 1)
    for i, j in zip(range(0, len(l), n), range(1, len(l) + 1)):
        yield l[i:i + n], j


mdf_expr = re.compile(r'.*\.mdf$')
mdf_dir = '/daqarea1/fest/mdf'
mdf_files = []

for mdf_file in sorted(os.listdir(mdf_dir)):
    if mdf_expr.match(mdf_file):
        mdf_files.append(os.path.join(mdf_dir, mdf_file))

for input_files, i in chunks(mdf_files, 150):
    output_basename = 'hlt1_00135282_%08d_1' % i
    cmd = [
        'Allen', '-g', '/daqarea1/fest/allen/fest_geometry', '--mdf',
        ','.join(input_files), '--events-per-slice', '1000', '-m', '1000',
        '-t', '4', '--configuration',
        '/daqarea1/fest/allen/configuration/config.json', '--output-file',
        f'/daqarea1/fest/mdf_hlt1/{output_basename}.mdf',
        '--monitoring-filename',
        f'/daqarea1/fest/mdf_hlt1/histos/{output_basename}.root'
    ]

    r = subprocess.run(cmd)
    if r.returncode != 0:
        print('Failed: {}'.format(' '.join(cmd)))
