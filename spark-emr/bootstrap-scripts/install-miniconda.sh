export SOFTWARE=~/software
export CMAKE_PREFIX_PATH="~/software"
export PATH=${SOFTWARE}/bin:$PATH
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -u -b -p ${SOFTWARE}


# Install packages
conda install -y python=3.7.10
conda install -y matplotlib scikit-learn pandas numpy
conda install -yc conda-forge pysoundfile librosa