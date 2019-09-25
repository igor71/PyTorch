# PyTorch
Building Docker Image Based on PyTorch

### Download PyTorch

`https://pypi.org/project/torch/#files`

### PyTorch-OpenVINO-GPU-Build-Docker
Create PyTorch & OpenVINO GPU Docker Image.
```
Ubuntu Version  -->> Ubuntu 18.04.2 LTS

docker inspect -f '{{index .Config.Labels "com.nvidia.cuda.version"}}' 0a1b1a956cdb

CUDA Version   -->> 10.1.130

docker inspect -f '{{index .Config.Labels "com.nvidia.cudnn.version"}}' 0a1b1a956cdb

CUDNN Version  -->> 7.5.0.56
```

### Manual Buils steps:
```
git clone --branch=master --depth=1 https://github.com/igor71/PyTorch/

cd PyTorch

docker build -f Dockerfile -t yi/tflow-vnc:python-3.6-pytorch-openvino .

yi-docker-run
```

### Check PyTorch installed properly:
```
cd /tmp
python PyTorch_Check.py
python -c "import torch as th; print(th.__version__)"
```
