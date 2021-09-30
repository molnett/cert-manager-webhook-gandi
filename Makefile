IMAGE_NAME := "cert-manager-webhook-gandi"
IMAGE_TAG := "latest"

OUT := $(shell pwd)/_out

$(shell mkdir -p "$(OUT)")

verify:
	go test -v .

build:
	sudo podman build --rm -t "$(IMAGE_NAME):$(IMAGE_TAG)" .

package:
	helm package deploy/cert-manager-webhook-gandi -d charts/
	helm repo index charts/ --url https://hexa-solutions.github.io/cert-manager-webhook-gandi/charts

.PHONY: rendered-manifest.yaml
rendered-manifest.yaml:
#	    --name cert-manager-webhook-gandi $BACKSLASH
	helm template \
        --set image.repository=$(IMAGE_NAME) \
        --set image.tag=$(IMAGE_TAG) \
        deploy/cert-manager-webhook-gandi > "$(OUT)/rendered-manifest.yaml"
