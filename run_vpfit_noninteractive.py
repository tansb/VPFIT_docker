import subprocess
import shutil
import os
import argparse


parser = argparse.ArgumentParser(
    description="Run VPFIT non-interactively on a provided file.")

parser.add_argument("filename", type=str, help="Path to the input file")

# set the current working directory and make a results dir
cwd = os.path.dirname(os.path.abspath(__file__))
print(cwd)
args = parser.parse_args()
data_path = args.filename
data_name = data_path.split('/')[-1].split('.')[0]
output_dir = os.path.join(cwd, 'vpfit_results')
# make the output dir if it doesnt already exist
os.makedirs(output_dir, exist_ok=True)

print('Saving output to ', output_dir)

# These are the commands needed to run VPfit from an input file then save
# the plot to an ascii file. note the empty line is needed!
my_commands = f"""F

{data_path}
y
as
y

n
n
"""

# initase the daughter process running vpfit
with subprocess.Popen("vpfit",
                      stdout=subprocess.PIPE,
                      stdin=subprocess.PIPE,
                      stderr=subprocess.STDOUT,
                      cwd=cwd) as p:
    try:
        stdout = p.communicate(input=my_commands.encode(), timeout=10)
    except subprocess.TimeoutExpired:
        print('did this work?')
        p.kill()
        raise RuntimeError("VPFIT timed out")

# print the VPfit output to the terminal
output = stdout[0].decode()
print(output)
if "Summary output was to" not in output:
    raise RuntimeError("VPFIT did not complete successfully.")

# Retrieve the name of the file that vpfit wrote the summary to
origin_output_fname = stdout[0].decode().split(
    "Summary output was to ")[1].split('\n')[0]

# Now rewrite the output to a person readable file name
shutil.move(os.path.join(cwd, origin_output_fname),
            os.path.join(output_dir, f'{data_name}_vpfit_output.txt'))

# Now save the plot to a new filename
shutil.move(os.path.join(cwd, 'vpfit_chunk001.txt'),
            os.path.join(output_dir, f'{data_name}_vpfit_plot.txt'))

# Also need to rewrite the plot file to get rid of the first line so that
# astropy can read it
with open(os.path.join(output_dir, f'{data_name}_vpfit_plot.txt'), 'r') as f:
    data = f.read().splitlines(True)

data[0] = 'Wavelength Flux Uncertainty VPfit\n'

with open(os.path.join(output_dir, f'{data_name}_vpfit_plot.txt'), 'w') as f:
    f.writelines(data)

print(f"Finished {data_name}")
