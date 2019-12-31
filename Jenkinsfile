pipeline {
  agent {label 'yi-tflow-vnc'}
    stages {
        stage('Import yi/tflow-gui Docker Image') {
            steps {
                sh '''#!/bin/bash -xe
                   # Bacic Docker Image For Pytorch ver. XXX
                     image_id="$(docker images -q yi/tflow-gui:latest)"
                     echo "Available Basic Docker Image Is: $image_id"

                   # Check If Docker Image Exist On Desired Server
		           if [ "$image_id" == "" ]; then
                     echo "Docker Image Does Not Exist!!!"
                     pv -f /media/common/DOCKER_IMAGES/Tflow-GUI/10.0-cudnn7-base/Ubuntu-18/yi-tflow-gui-latest.tar | docker load
                     docker tag 0a1b1a956cdb yi/tflow-gui:latest
                   elif [ "$image_id" != "0a1b1a956cdb" ]; then
		             echo "Wrong Docker Image!!! Removing..."
                     docker rmi -f yi/tflow-gui:latest
                     pv -f /media/common/DOCKER_IMAGES/Tflow-GUI/10.0-cudnn7-base/Ubuntu-18/yi-tflow-gui-latest.tar | docker load
                     docker tag 0a1b1a956cdb yi/tflow-gui:latest
                   else
                     echo "Docker Image Already Exist"
                   fi
		           '''
            }
        }
        stage('Build Docker Image ') {
            steps {
                sh '''#!/bin/bash -xe
	              docker build -f Dockerfile -t yi/tflow-vnc:python-3.6-pytorch-openvino-tf .
		   '''
            }
        }
	    stage('Testing Docker Image') {
            steps {
                sh '''#!/bin/bash -xe
		          echo 'Hello, PyTorch_Docker'
                  image_id="$(docker images -q yi/tflow-vnc:python-3.6-pytorch-openvino-tf)"
                  if [[ "$(docker images -q yi/tflow-vnc:python-3.6-pytorch-openvino-tf 2> /dev/null)" == "$image_id" ]]; then
                     docker inspect --format='{{range $p, $conf := .RootFS.Layers}} {{$p}} {{end}}' $image_id
                  else
                     echo "It appears that current docker image corrupted!!!"
                     exit 1
                  fi
                   '''
		    }
		}
		stage('Save & Load Docker Image') {
            steps {
                sh '''#!/bin/bash -xe
		           echo 'Saving Docker image into tar archive'
                   docker save yi/tflow-vnc:python-3.6-pytorch-openvino-tf | pv | cat > $WORKSPACE/yi-tflow-vnc-python-3.6-pytorch-openvino-tf.tar

                   echo 'Remove Original Docker Image'
	               CURRENT_ID=$(docker images | grep -E '^yi/tflow-vnc.*'python-3.6-pytorch-openvino-tf'' | awk -e '{print $3}')
                   docker rmi -f yi/tflow-vnc:python-3.6-pytorch-openvino-tf

                   echo 'Loading Docker Image'
                   pv -f $WORKSPACE/yi-tflow-vnc-python-3.6-pytorch-openvino-tf.tar | docker load
	               docker tag $CURRENT_ID yi/tflow-vnc:python-3.6-pytorch-openvino-tf

                   echo 'Removing temp archive.'
                   rm $WORKSPACE/yi-tflow-vnc-python-3.6-pytorch-openvino-tf.tar

	               echo 'Removing Basic Docker Image'
	               docker rmi -f yi/tflow-gui:latest
                   '''
		    }
		}
    }
	post {
            always {
               script {
                  if (currentBuild.result == null) {
                     currentBuild.result = 'SUCCESS'
                  }
               }
               step([$class: 'Mailer',
                     notifyEveryUnstableBuild: true,
                     recipients: "igor.rabkin@xiaoyi.com",
                     sendToIndividuals: true])
            }
         }
}