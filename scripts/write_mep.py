import os
import subprocess
import re

def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    for i, j in zip(range(0, len(l), n), range(1, len(l) + 1)):
        yield l[i:i+n], j


mdf_expr = re.compile(r'.*\.mdf$')
mdf_dir = '/daqarea1/fest/mdf'
mdf_files = []

for mdf_file in sorted(os.listdir(mdf_dir)):
    if mdf_expr.match(mdf_file):
        mdf_files.append(os.path.join(mdf_dir, mdf_file))


for input_files, i in chunks(mdf_files, 5):
    output_basename = '00135282_%08d_1' % i
    r = subprocess.run(['which', 'gentest.exe'], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    gentest = r.stdout.decode().strip()
    cmd = [gentest, 'libDataflowUtils.so', 'pcie_encode_many',
           '-o', f'/daqarea1/fest/mep/{output_basename}.mep',
           '-p', '1000', '-e', '5000']
    for f in input_files:
        cmd += ['-i', f]

    r = subprocess.run(cmd)
    if r.returncode != 0:
        print('Failed: {}'.format(' '.join(cmd)))

