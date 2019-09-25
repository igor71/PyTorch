FROM yi/tflow-gui:latest

MAINTAINER Igor Rabkin <igor.rabkin@xiaoyi.com>

#################################################
#  Update repositories -- we will need them all #
#  the time, also when container is run         #
#################################################

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update

############################################################
#            Installing Dependences PyTorch & Python       #
############################################################

RUN apt-get install -y --no-install-recommends \
    openssh-client \
    mlocate \
    screen \
    sudo \
    pv \
    cpio \
    libgraphviz-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    

#################################################
#     Python 3.6 installations for dev          #
#################################################

ENV PYTHON_VERSION=3.6.8
# If this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.2.3
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
#              Pick up some Python packages                      #
################################################################## 

RUN python -m pip --no-cache-dir install \ 
    networkx \
    pytest \
    ipykernel \
    numpy \
    pandas \
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
    h5py \
    cvxpy \
    urllib3==1.21.1 && \
    python -m ipykernel.kernelspec && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*
    

#########################################
#       Install PyTorch & Dependences    #
##########################################
   
RUN python -m pip --no-cache-dir install \
    ipdb \
    imageio \
    graphviz \
    tensorboardX \
    qpth==0.0.15 && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*
	  
RUN git clone https://github.com/pygraphviz/pygraphviz.git && \
    cd pygraphviz && \
    python setup.py install --include-path=/usr/include/graphviz --library-path=/usr/lib/graphviz/ && \
    rm -rf pygraphviz && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*	  

ARG PYTORCH_VER=torch-1.2.0-cp36-cp36m-manylinux1_x86_64.whl	  
RUN curl -OSL ftp://jenkins-cloud/pub/Tflow-VNC-Soft/PyTorch/${PYTORCH_VER} -o ${PYTORCH_VER} && \
      python -m pip --no-cache-dir install \
      ${PYTORCH_VER} \
      torchvision==0.4 \
      torchnet && \
	  rm -f ${PYTORCH_VER} && \
      apt-get clean && \ 
      rm -rf /var/lib/apt/lists/*
	  
COPY Config/PyTorch_Check.py /tmp


##################################################
# Configure the build for our CUDA configuration #
##################################################

ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV TORCH_CUDA_ARCH_LIST "5.2 6.0 6.1 7.0+PTX"
ENV TORCH_NVCC_FLAGS "-Xfatbin -compress-all" 


#################################################
#                Installing OpenVINO             #
##################################################

ARG VER=l_openvino_toolkit_p_2019.2.242.tgz
COPY Config/openvino.conf_2019.2.242 /etc/ld.so.conf.d/openvino.conf
RUN cd /tmp && \
    curl -OSL ftp://jenkins-cloud/pub/Tflow-VNC-Soft/OpenVINO/${VER} -o ${VER} && \
    pv -f ${VER} | tar xpzf - -C $PWD && \
    cd l_openvino_toolkit_p_2019.2.242 && \
    sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh -s silent.cfg --ignore-signature && \
    cd /opt/intel/openvino/install_dependencies && \
    ./install_openvino_dependencies.sh && \
    cd /opt/intel/openvino_2019.2.242/deployment_tools/model_optimizer/install_prerequisites && \
    ./install_prerequisites_onnx.sh && \
    pv -f /opt/intel/openvino/bin/setupvars.sh > /tmp/setupvars.sh && \
    chmod o+x /tmp/setupvars.sh && \
    ldconfig && \
    cd /tmp && \
    rm -rf l_openvino_toolkit_p_2019.2.242* && \
    cd /opt/intel/openvino_2019.2.242/deployment_tools/inference_engine/samples/python_samples/classification_sample && \
    sed -i "24 a sys.path.append('/opt/intel/openvino_2019.2.242/python/python3.6/')" classification_sample.py && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


#######################################
# Set User OPENVINO User To The image #
#######################################

RUN useradd -m -d /home/openvino -s /bin/bash openvino && \
    echo "openvino:openvino" | chpasswd && \
    sed -i '23 a openvino  ALL=(ALL)  NOPASSWD: ALL' /etc/sudoers
    
    
###########################################################
#       Installing yi-dockeradmin inside docker image     #
###########################################################

RUN ln -s /media/common/IT/YiDockerScripts/yi-dockeradmin /usr/local/bin/yi-dockeradmin && \
    sed -i '$a\\' /etc/bash.bashrc && \
    sed -i '$a\###### Adding yi-dockeradmin Function ######\' /etc/bash.bashrc && \
    sed -i '$a\source /usr/local/bin/yi-dockeradmin\' /etc/bash.bashrc && \
    sed -i '$a\############################################\' /etc/bash.bashrc
    
    
