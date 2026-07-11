IMAGE_VERSION=1.2.0

deploy:
	IMAGE_VERSION=$(IMAGE_VERSION) ./scripts/deploy-k8s.sh

all: deploy
