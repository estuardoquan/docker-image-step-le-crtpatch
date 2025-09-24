AUTHOR=dqio
IMAGE=crtpatch

TAG=${AUTHOR}/${IMAGE}

all:

docker-build: docker-build-crtpatch

docker-build-crtpatch:
        docker build -t ${TAG}:production ./

