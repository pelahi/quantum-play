#!/bin/bash -l
# Allocate slurm resources, edit as necessary
# Here we request the appropriate GPU partition on a system
#SBATCH --partition=gpu-dev
#SBATCH -A <project>-gpu

# Since jupyterhub is not mpi enabled, we just use one task, 1 gpu but reserve
# all the mem for the test if we want large runs
#SBATCH --ntasks=1
#SBATCH --exclusive
#SBATCH --gpus-per-task=1

#SBATCH --time=02:00:00
#SBATCH --job-name=jupyter_notebook
#SBATCH --export=NONE

# now copy information to load appropriate modules 
 
# pennylane versions
tool_name="pennylane-hip"

pl_ver="0.32.0"
# host versions
py_ver="3.10.10"
python_major_ver="3.10"
pip_ver="23.1.2-py3.10.10"
# why this very new setuptools version?
st_ver="68.0.0-py3.10.10"
# lets try the older version that is compatible with numpy
st_ver="59.4.0-py3.10.10"
# now some packages
numpy_ver="1.23.4"
scipy_ver="1.8.1"
scikit_ver="1.1.3"
cython_ver="0.29.32"
h5py_ver="3.7.0"
mpi4py_ver="3.1.4-py3.10.10"

# gpu
rocm_ver="5.4.3"

# load modules
module load python/$py_ver
module load py-pip/$pip_ver
module load py-setuptools/$st_ver
module load py-numpy/$numpy_ver
module load py-scipy/$scipy_ver
module load py-mpi4py/$mpi4py_ver
module load py-scikit-learn/$scikit_ver
module load rocm/$rocm_ver
module load craype-accel-amd-gfx90a

# internal variables - do not edit
install_dir=$(pwd)
lib_dir="$install_dir/lib/python${python_major_ver}/site-packages"
bin_dir="$install_dir/bin"
#
export PYTHONPATH="$lib_dir:$PYTHONPATH"
export PATH="$bin_dir:$PATH"


source $(pwd)/pyvenv-pennylane/bin/activate

module list
echo $PYTHONPATH
echo $PATH


# Set our working directory
# This is the directory we'll mount to /home/jovyan in the container
# Should be in a writable path with some space, like /scratch
dir="$(pwd)/jupyter-dir"

# You should not need to edit the lines below

# Prepare the working directory
mkdir -p ${dir}
cd ${dir}

# Get the hostname
# We'll set up an SSH tunnel to connect to the Juypter notebook server
host=$(hostname)
 
# Set the port for the SSH tunnel
# This part of the script uses a loop to search for available ports on the node;
# this will allow multiple instances of GUI servers to be run from the same host node
port="8888"
pfound="0"
while [ $port -lt 65535 ] ; do
  check=$( ss -tuna | awk '{print $4}' | grep ":$port *" )
  if [ "$check" == "" ] ; then
    pfound="1"
    break
  fi
  : $((++port))
done
if [ $pfound -eq 0 ] ; then
  echo "No available communication port found to establish the SSH tunnel."
  echo "Try again later. Exiting."
  exit
fi
 
echo "*****************************************************"
echo "Setup - from your laptop do:"
echo "ssh -N -f -L ${port}:${host}:${port} $USER@$PAWSEY_CLUSTER.pawsey.org.au"
echo "*****"
echo "The launch directory is: $dir"
echo "*****************************************************"
echo ""
echo "*****************************************************"
echo "Terminate - from your laptop do:"
echo "kill \$( ps x | grep 'ssh.*-L *${port}:${host}:${port}' | awk '{print \$1}' )"
echo "*****************************************************"
echo ""

jupyter notebook \
  --no-browser \
  --port=${port} --ip=0.0.0.0 \
  --notebook-dir=${dir}
