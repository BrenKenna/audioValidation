# Install updates
sudo su
yum update -y 
yum install -y libsndfile.x86_64 libsndfile-utils.x86_64 libsndfile-devel.x86_64 git


# Install miniconda
export SOFTWARE=/opt/conda
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -u -b -p ${SOFTWARE}
export CMAKE_PREFIX_PATH="/opt/conda"
export PATH=${SOFTWARE}/bin:$PATH


# Config channels
conda init bash
conda config --append channels bioconda
conda config --append channels conda-forge


# Create env
conda create --name audioValEnv python==3.7.5 boto3
conda activate audioValEnv
conda install -y pandas scikit-learn matplotlib
conda install -yc conda-forge pysoundfile librosa
mkdir -m 777 /tmp/NUMBA_CACHE_DIR


# Install audio validator
cd /opt/conda/envs/audioValEnv/lib/python3.7/site-packages
git clone --recursive https://github.com/BrenKenna/audioValidation.git
cd audioValidation