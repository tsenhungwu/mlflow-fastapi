IMAGE_VERSION=1.1.0

deploy:
	IMAGE_VERSION=$(IMAGE_VERSION) ./scripts/deploy-k8s.sh

all: deploy
