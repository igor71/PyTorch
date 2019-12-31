FROM yi/tflow-gui:latest
 
MAINTAINER Igor Rabkin <igor.rabkin@xiaoyi.com>

###################################################################
#            Installing Dependences For PyTorch & Caffe           #
###################################################################

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    doxygen \
    cpio \
    mlocate \
    screen \
    sudo \
    pv && \	
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


#################################################
#     Python 3.6 installations for dev          #
#################################################

ENV PYTHON_VERSION=3.6.8
# If this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.3.1
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK, fixing...
# http://bugs.python.org/issue19846
ENV LANG C.UTF-8

# Ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# Extra dependencies & python installation
RUN apt-get update && apt-get install -y --no-install-recommends \
	tk-dev \
	libpq-dev \
	libssl-dev \
	openssl \
	libffi-dev \
	zlib1g-dev \
	libsqlite3-dev \
	libncurses5 \
	libncurses5-dev \
	libncursesw5 \
	&& rm -rf /var/lib/apt/lists/*

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D

RUN set -ex \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip \
	&& make -j "$(nproc)" \
	&& make install \
	&& ldconfig \
	\
	&& find /usr/local -depth \
		\( \
		\( -type d -a \( -name test -o -name tests \) \) \
		-o \
		\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf /usr/src/python \
	\
	&& python3 --version

# Make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
        && ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s /usr/local/bin/python3.6 /usr/bin/python3.6.8 \
	&& ln -s python3-config python-config
	
##################################	
# Installing PIP and Dependences #
##################################	

RUN set -ex; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
		\( -type d -a \( -name test -o -name tests \) \) \
		-o \
		\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py 
	

################################################################## 
#              Pick up some TF dependencies                      #
##################################################################

RUN apt-get update && apt-get install -y --no-install-recommends \ 		 
    libfreetype6-dev \
    libpng-dev \ 
    libzmq3-dev \
    libcurl3-dev \
    libgoogle-perftools-dev \
    zlib1g-dev \
    pkg-config \  
    python3-tk && \    
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/* 
    
   
RUN python -m pip --no-cache-dir install \ 
    networkx==2.3 \
    pytest \
    ipykernel \
    numpy \
    pandas==0.24 \
    scipy \
    sklearn \
    scikit-learn \
    tqdm \
    click==6.7 \
    more_itertools \
    utils \
    bs4 \
    opencv-python \
    python3-utils \
    scikit-image \
    xmltodict \
    easydict \
    sacred \
    tables \
    glances \
    gpustat \
    texttable \
    albumentations \
    cvxpy \
    urllib3==1.21.1 && \
    python -m ipykernel.kernelspec && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*
    

##########################################
#       Install PyTorch & Dependences    #
##########################################

  RUN apt-get update && apt-get install -y --no-install-recommends \
      libgraphviz-dev 
        
  RUN python -m pip --no-cache-dir install \
      ipdb \
      imageio \
      graphviz \
      tensorboardX \
      qpth && \
      apt-get clean && \ 
      rm -rf /var/lib/apt/lists/*
	  
  RUN git clone https://github.com/pygraphviz/pygraphviz.git && \
      cd pygraphviz && \
      python setup.py install --include-path=/usr/include/graphviz --library-path=/usr/lib/graphviz/ && \
      rm -rf pygraphviz && \
      apt-get clean && \ 
      rm -rf /var/lib/apt/lists/*	  
	  
  RUN curl -OSL ftp://jenkins-cloud/pub/Tflow-VNC-Soft/PyTorch/torch-1.3.1-cp36-cp36m-manylinux1_x86_64.whl -o torch-1.3.1-cp36-cp36m-manylinux1_x86_64.whl && \
      python -m pip --no-cache-dir install \
      torch-1.3.1-cp36-cp36m-manylinux1_x86_64.whl \
      torchvision===0.4.2 \
      torchnet && \
      apt-get clean && \ 
      rm -f torch-1.3.1-cp36-cp36m-manylinux1_x86_64.whl && \
      rm -rf /var/lib/apt/lists/*
      
      
#################################################
#     Install HDF5 with multithread support     #
#################################################

RUN curl -OSL https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar && \
    tar -xvf hdf5-1.8.20.tar && \
    cd hdf5-1.8.20 && \
    ./configure --enable-threadsafe  --enable-unsupported --prefix /usr/local && \
    nc=`nproc` && \
    make -j$nc && \
    make install && \
    cd .. && \
    rm hdf5-1.8.20.tar && rm -rf hdf5-1.8.20.tar && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*
    
    ENV HDF5_DIR=/usr/local 
    RUN python3.6 -m pip --no-cache-dir install --no-binary=h5py h5py


#################################################
#                Installing OpenVINO             #
##################################################

ARG VER=l_openvino_toolkit_p_2019.3.334.tgz
COPY Config/openvino.conf_2019.3.334 /etc/ld.so.conf.d/openvino.conf
RUN cd /tmp && \
    curl -OSL ftp://jenkins-cloud/pub/Tflow-VNC-Soft/OpenVINO/${VER} -o ${VER} && \
    pv -f ${VER} | tar xpzf - -C $PWD && \
    cd l_openvino_toolkit_p_2019.3.334 && \
    sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh -s silent.cfg --ignore-signature && \
    cd /opt/intel/openvino/install_dependencies && \
    ./install_openvino_dependencies.sh && \
    cd /opt/intel/openvino_2019.3.334/deployment_tools/model_optimizer/install_prerequisites && \
    ./install_prerequisites_onnx.sh && \
    pv -f /opt/intel/openvino/bin/setupvars.sh > /tmp/setupvars.sh && \
    chmod o+x /tmp/setupvars.sh && \
    ldconfig && \
    cd /tmp && \
    rm -rf l_openvino_toolkit_p_2019.3.334* && \
    cd /opt/intel/openvino_2019.3.334/deployment_tools/inference_engine/samples/python_samples/classification_sample && \
    sed -i "24 a sys.path.append('/opt/intel/openvino_2019.3.334/python/python3.6/')" classification_sample.py && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


#######################################
# Set User OPENVINO User To The image #
#######################################

RUN useradd -m -d /home/openvino -s /bin/bash openvino && \
    echo "openvino:openvino" | chpasswd && \
    sed -i '23 a openvino  ALL=(ALL)  NOPASSWD: ALL' /etc/sudoers
    
   
###################################
# Install TensorFlow GPU version. #
###################################

ARG TF_VER=tensorflow-1.15.0-cp36-cp36m-linux_x86_64.whl
RUN curl -OSL ftp://jenkins-cloud/pub/Tensorflow-1.15.0-10.0-cudnn7-devel-ubuntu16.04-Server_22/${TF_VER} -o ${TF_VER} && \
      pip --no-cache-dir install --upgrade ${TF_VER} && \
      rm -f ${TF_VER} && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/*
      
  
##################################################
# Configure the build for our CUDA configuration #
##################################################

ENV CI_BUILD_PYTHON python
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV TF_NEED_CUDA 1
ENV TF_CUDA_COMPUTE_CAPABILITIES=5.2,6.1,7.0
ENV TF_CUDA_VERSION=10.0
ENV TF_CUDNN_VERSION=7
ENV TF_NCCL_VERSION=2
ENV TF_NEED_TENSORRT 0


###########################################################
#       Installing yi-dockeradmin inside docker image     #
###########################################################

RUN ln -s /media/common/IT/YiDockerScripts/yi-dockeradmin /usr/local/bin/yi-dockeradmin && \
    sed -i '$a\\' /etc/bash.bashrc && \
    sed -i '$a\###### Adding yi-dockeradmin Function ######\' /etc/bash.bashrc && \
    sed -i '$a\source /usr/local/bin/yi-dockeradmin\' /etc/bash.bashrc && \
    sed -i '$a\############################################\' /etc/bash.bashrc
