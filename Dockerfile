FROM yi/tflow-gui:latest

MAINTAINER Igor Rabkin <igor.rabkin@xiaoyi.com>

#################################################
#  Update repositories -- we will need them all #
#  the time, also when container is run         #
#################################################

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update

###################################################################
#            Installing Dependences PyTorch, Caffe & Python       #
###################################################################

RUN apt-get install -y --no-install-recommends \
    apt-utils \
    python3-distutils \
    python3-setuptools \
    python3-dev \
    doxygen \
    cpio \
    libgraphviz-dev \
    openssh-client \
    mlocate \
    screen \
    sudo \
    pv \
    libatlas-base-dev \ 
    libboost-all-dev \ 
    libgflags-dev \ 
    libgoogle-glog-dev \ 
    libhdf5-serial-dev \ 
    libleveldb-dev \ 
    liblmdb-dev \ 
    libopencv-dev \ 
    libprotobuf-dev \ 
    libsnappy-dev \
    libopenblas-dev && \	
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
	
	
###############################################################
#            Installing protobuf-compiler ver. 2.6.1          #
###############################################################

RUN cd /tmp && \
curl -fSsL -O https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz && \
tar xzf protobuf-2.6.1.tar.gz && \
rm -f protobuf-2.6.1.tar.gz && \
cd protobuf-2.6.1 && \
./configure && \
make -j$nc && \
make check && \
make install && \
ldconfig && \
cd .. && \
rm -rf protobuf-2.6.1 && \
protoc --version
    

###########################################################
#            Setting Python3 Alias For All Users          #
###########################################################

RUN sed -i '$a\\' /etc/bash.bashrc && \
    sed -i '$a\###### Use Python 3.6 by default ###########\' /etc/bash.bashrc && \
    sed -i '$a\alias python='python3.6'\' /etc/bash.bashrc && \
    sed -i '$a\############################################\' /etc/bash.bashrc

ARG PY=python3.6
RUN ${PY} --version && \
    curl -fSsL -O ftp://jenkins-cloud/pub/Develop/get-pip.py && \
    ${PY} get-pip.py && \
    rm get-pip.py
    
    
#######################################
#            Installing cmake         #
#######################################

RUN \
    cd ~ && \
    version=3.12 && \
    build=3 && \
    mkdir ~/temp && \
    cd temp && \
    wget https://cmake.org/files/v$version/cmake-$version.$build.tar.gz && \
    tar -xzvf cmake-$version.$build.tar.gz && \
    cd cmake-$version.$build && \
    ./bootstrap && \
    make -j$nc && \
    make install && \
    cmake --version && \
    cd ~ && \
    rm -rf temp
    
    
################################################################## 
#              Pick up some Python packages                      #
################################################################## 

RUN curl -SL ftp://jenkins-cloud/pub/Tflow-VNC-Soft/PyTorch/th_tf_requirements.txt -o /tmp/th_tf_requirements.txt && \
    for th_req in $(cat /tmp/th_tf_requirements.txt); do ${PY} -m pip --no-cache-dir install $th_req; done && \
    rm -f  /tmp/th_tf_requirements.txt && \
    ${PY} -m ipykernel.kernelspec && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*
    

#########################################
#       Install PyTorch & Dependences    #
##########################################
   
RUN ${PY} -m pip --no-cache-dir install \
    ipdb \
    imageio \
    graphviz \
    tensorboardX \
    qpth==0.0.15 && \
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/*
	  
ARG PYTORCH_VER=torch-1.3.0-cp36-cp36m-manylinux1_x86_64.whl	  
RUN curl -OSL ftp://jenkins-cloud/pub/Tflow-VNC-Soft/PyTorch/${PYTORCH_VER} -o ${PYTORCH_VER} && \
      ${PY} -m pip --no-cache-dir install \
      ${PYTORCH_VER} \
      torchvision \
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
    
    
#######################################
#            Installing ONNX          #
#######################################

RUN cd /tmp && \
    git clone --recursive https://github.com/onnx/onnx.git && \
    cd onnx && \
    ${PY} setup.py install && \
    cd .. && \
    rm -rf onnx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
	
	
#############################################
#          Set Caffe ENV Variables          #
#############################################

ENV PYTHONPATH="${PYTHONPATH}:/opt/caffe/python"
ENV CUDA_ARCH_BIN="52 60 61" 
 
 
#######################################
#            Installing CAFFE         #
#######################################

RUN cd /opt && \
    git clone https://github.com/BVLC/caffe.git && \
    cd caffe/python && \
    sed -i 's/python-dateutil>=1.4,<2/python-dateutil>=2.6.1/g' requirements.txt && \
    for req in $(cat requirements.txt) pydot; do pip install $req; done && cd .. && \
    sed -i '425d' Makefile && \
    sed -i '424 a NVCCFLAGS += -D_FORCE_INLINES -ccbin=$(CXX) -Xcompiler -fPIC $(COMMON_FLAGS)' Makefile && \
    curl -OSL ftp://jenkins-cloud/pub/Tflow-VNC-Soft/Caffe/Makefile.config -o Makefile.config && \
    git clone https://github.com/NVIDIA/nccl.git && cd nccl && \
    sed -i '28d' makefiles/common.mk && \
    sed -i '28d' makefiles/common.mk && \
    sed -i '27 a CUDA8_GENCODE = -gencode=arch=compute_35,code=sm_35 \\' makefiles/common.mk && \
    make -j$nc install && cd .. && rm -rf nccl && \
    updatedb && \
    locate nccl| grep "libnccl.so" | tail -n1 | sed -r 's/^.*\.so\.//' && \
    mkdir build && \
    sed -i '35d' CMakeLists.txt && \
    sed -i '34 a set(python_version "3" CACHE STRING "Specify which Python version to use")' CMakeLists.txt && \
    cd build && \
    cmake -D CUDA_ARCH_NAME=Manual -D CUDA_ARCH_BIN="${CUDA_ARCH_BIN}" \
          -D USE_CUDNN=1 -D USE_NCCL=1 .. && \
    make -j$nc && \
    make pycaffe -j$nc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
	
ENV CAFFE_ROOT=/opt/caffe	
ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig


RUN cd /tmp && \
    git clone --recursive https://github.com/onnx/onnx.git && \
    cd onnx && \
    ${PY} setup.py install && \
    cd .. && \
    rm -rf onnx && \
    apt-get clean
    

###########################################################
#       Installing yi-dockeradmin inside docker image     #
###########################################################
RUN ln -s /media/common/IT/YiDockerScripts/yi-dockeradmin /usr/local/bin/yi-dockeradmin && \
    sed -i '$a\\' /etc/bash.bashrc && \
    sed -i '$a\###### Adding yi-dockeradmin Function ######\' /etc/bash.bashrc && \
    sed -i '$a\source /usr/local/bin/yi-dockeradmin\' /etc/bash.bashrc && \
    sed -i '$a\############################################\' /etc/bash.bashrc
