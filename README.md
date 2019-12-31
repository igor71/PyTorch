# PyTorch-OpenVINO
Building Docker Image Based on PyTorch, OpenVino & Tensorflow.
This image used build form the sources Python 3.6.8, located in `/usr/local/bin directory`.

### Download PyTorch

`https://pypi.org/project/torch/#files`

### Basic Image with  CUDA 10

```
Build yi/tflow-vnc:X.X.X-python-3.6-pytorch-openvino-tf Image

Ubuntu Version  -->> Ubuntu 18.04.2 LTS

docker inspect -f '{{index .Config.Labels "com.nvidia.cuda.version"}}' 0a1b1a956cdb

CUDA Version   -->> 10.0.130

docker inspect -f '{{index .Config.Labels "com.nvidia.cudnn.version"}}' 0a1b1a956cdb

CUDNN Version  -->> 7.5.0.56
```

### Manual Buils steps:
```
git clone --branch=PyTorch-OpenVINO-Tensorflow-Custom-PY-3.6.8 --depth=1 https://github.com/igor71/PyTorch/

cd PyTorch

docker build -f Dockerfile -t yi/tflow-vnc:python-3.6-pytorch-openvino-tf .

yi-docker-run
```

  
### Check PyTorch installed properly:
```
python -c 'import h5py; print(h5py.version.info)'
   
python -c "import torch; print(torch.__version__)"
     
python -c 'import tensorflow as tf; print(tf.__version__)'

python -c "import tensorflow as tf; print(tf.contrib.eager.num_gpus())"
    
```
 
