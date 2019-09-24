FROM yi/tflow-vnc:python-3.6-pytorch

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
    libgraphviz-dev \
    python3-distutils \
    python3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    

RUN ln -sfn /usr/bin/python3.6 /usr/bin/python && \
     python --version && \
     curl -fSsL -O ftp://jenkins-cloud/pub/Develop/get-pip.py && \
     python3.6 get-pip.py && \
     rm get-pip.py
 
    
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
    qpth==0.15 && \
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
ENV	TORCH_CUDA_ARCH_LIST="5.2 6.0 6.1 7.0+PTX"


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
    
    
