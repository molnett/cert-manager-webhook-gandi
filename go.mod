module github.com/bwolf/cert-manager-webhook-gandi

go 1.12

require (
	github.com/jetstack/cert-manager v0.12.0
	k8s.io/apiextensions-apiserver v0.0.0-20191114105449-027877536833
	k8s.io/apimachinery v0.0.0-20191028221656-72ed19daf4bb
	k8s.io/client-go v0.0.0-20191114101535-6c5935290e33
	k8s.io/klog v1.0.0
)

replace github.com/prometheus/client_golang => github.com/prometheus/client_golang v0.9.4

replace github.com/evanphx/json-patch => github.com/evanphx/json-patch v0.0.0-20190203023257-5858425f7550
