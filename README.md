# PyTorch
Building Docker Image Based on PyTorch, OpenVino, Caffe v.1.0 & Tensorflow. This image used aliases for Python 3.6.8.
Adding symbolic link ln -s /usr/bin/python3.6 /usr/bin/python will break TortoiseHG app.

### Download PyTorch

`https://pypi.org/project/torch/#files`

### PyTorch-OpenVINO-Caffe-GPU-Build-Docker
Create PyTorch, Caffe & OpenVINO GPU Docker Image.
```
Ubuntu Version  -->> Ubuntu 18.04.2 LTS

docker inspect -f '{{index .Config.Labels "com.nvidia.cuda.version"}}' 0a1b1a956cdb

CUDA Version   -->> 10.1.130

docker inspect -f '{{index .Config.Labels "com.nvidia.cudnn.version"}}' 0a1b1a956cdb

CUDNN Version  -->> 7.5.0.56
```

### Manual Buils steps:
```
git clone --branch=PyTorch-OpenVINO-Caffe-Tensorflow --depth=1 https://github.com/igor71/PyTorch/

cd PyTorch

docker build -f Dockerfile -t yi/tflow-vnc:python-3.6-pytorch-openvino-caffe-tf .

yi-docker-run
```

### Check PyTorch installed properly:
```
cd /tmp
python PyTorch_Check.py
python -c "import torch as th; print(th.__version__)"
```
