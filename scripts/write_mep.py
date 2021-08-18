import os
import subprocess
import re
import json
import argparse


parser = argparse.ArgumentParser()
parser.add_argument(dest="n_meps", type=int, help="number of MEPs")
parser.add_argument(dest="packing", type=int, help="MEP packing factor")
parser.add_argument(dest="input_dir", help="Input MDF dir")
parser.add_argument(dest="output_dir", help="Output directory")
parser.add_argument("--failed", dest="failed",
                    default="/daqarea1/fest/mep/failed.json",
                    help="JSON file contained MDFs to skip")


args = parser.parse_args()


def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    for i, j in zip(range(0, len(l), n), range(1, len(l) + 1)):
        yield l[i:i+n], j



# def size_chunks(l, sizes, target):
#     """ Yield successive n-sized chunks from l.
#     """
#     i = 0
#     c = 0
#     end = 0
#     while end < len(l):
#         mep_size = 0
#         for j in range(i, len(l)):
#             mep_size += sizes[l[j]]
#             print(c, i, j, mep_size)
#             if mep_size >= target:
#                 start = i
#                 end = j + 1
#                 i = j + 1
#                 c += 1
#                 break
#         yield (l[start:end], c)


        
mdf_expr = re.compile(r'.*\.mdf$')
mdf_files = set()

for mdf_file in sorted(os.listdir(args.input_dir)):
    if mdf_expr.match(mdf_file):
        mdf_files.add(os.path.join(args.input_dir, mdf_file))


print("Number of MDF files found: {}".format(len(mdf_files)))


with open(args.failed) as jf:
    failed_info = json.load(jf)


for d in failed_info.values():
    for failed in d['input']:
        if failed in mdf_files:
            mdf_files.remove(failed)


mdf_files = sorted(list(mdf_files))
print("Number of MDF files after removing failed: {}".format(len(mdf_files)))

sizes = {}
for mdf_file in mdf_files:
    sizes[mdf_file] = os.stat(mdf_file).st_size / 1024


sc = [c for c in chunks(mdf_files, 1)]
for input_files, i in sc:
    output_basename = '00135282_%08d_1' % i
    r = subprocess.run(['which', 'gentest.exe'], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    gentest = r.stdout.decode().strip()
    cmd = [gentest, 'libDataflowUtils.so', 'pcie_encode_many',
           '-o', f'/daqarea1/fest/mep/{output_basename}.mep',
           '-p', '10000', '-e', '8']
    for f in input_files:
        cmd += ['-i', f]

    r = subprocess.run(cmd)

