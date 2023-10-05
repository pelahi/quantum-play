#!/bin/bash -l
# an example of running jupyter
# Allocate slurm resources, edit as necessary
# Here we request the appropriate GPU partition on a system
#SBATCH --partition=gpu-dev
#SBATCH -A <project>-gpu
#or if requesting a cpu only run try 
#SBATCH --partition=debug
#SBATCH -A <project>

# Since jupyterhub is not mpi enabled, we just use one task
#SBATCH --ntasks=1
# to run large jobs ask for exclusive and mem=0
#SBATCH --exclusive
#SBATCH --mem=0

# if using gpu, try a single gpu 
#SBATCH --gpus-per-task=1
# here don't ask for memory, just exclusive

#SBATCH --time=02:00:00
#SBATCH --job-name=jupyter_notebook
#SBATCH --export=NONE


# load appropriate modules 
module load python/$py_ver
module load py-pip/$pip_ver
module load py-setuptools/$st_ver
module load py-numpy/$numpy_ver
module load py-scipy/$scipy_ver
module load py-mpi4py/$mpi4py_ver
module load py-scikit-learn/$scikit_ver

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
