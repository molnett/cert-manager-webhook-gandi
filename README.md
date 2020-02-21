# ACME webhook for Gandi (cert-manager-webhook-gandi)
`cert-manager-webhook-gandi` is an ACME webhook for [cert-manager]. It provides an ACME (read: Let's Encrypt) webhook for [cert-manager], which allows to use a `DNS-01` challenge with [Gandi]. This allows to provide Let's Encrypt certificates to [Kubernetes] for service protocols other than HTTP and furthermore to request wildcard certificates. Internally it uses the [Gandi LiveDNS API] to communicate with Gandi.

Quote about the [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge):

> This challenge asks you to prove that you control the DNS for your domain name by putting a specific value in a TXT record under that domain name. It is harder to configure than HTTP-01, but can work in scenarios that HTTP-01 can’t. It also allows you to issue wildcard certificates. After Let’s Encrypt gives your ACME client a token, your client will create a TXT record derived from that token and your account key, and put that record at _acme-challenge.<YOUR_DOMAIN>. Then Let’s Encrypt will query the DNS system for that record. If it finds a match, you can proceed to issue a certificate!


## Building
Build the container image `cert-manager-webhook-gandi:latest`:

    make build


### Minikube
1. Build this webhook in Minikube

        minikube start --memory=4G --more-options
        eval $(minikube docker-env)
        make build
        docker images | grep webhook

2. Install cert-manager

        kubectl create namespace cert-manager
        kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.13/deploy/manifests/00-crds.yaml
        helm repo add jetstack https://charts.jetstack.io
        helm install cert-manager --namespace cert-manager jetstack/cert-manager
        kubectl get pods --namespace cert-manager --watch

    **Note**: ensure that the custom CRDS of cert-manager match the major version of the cert-manager release by comparing the URL of the CRDS with the helm info of the charts app version:

            helm search repo jetstack

    Example output

            NAME                    CHART VERSION   APP VERSION     DESCRIPTION
            jetstack/cert-manager   v0.13.1         v0.13.1         A Helm chart for cert-manager

3. Create the secret to keep the Gandi API key

        kubectl create secret generic gandi-credentials \
            --namespace cert-manager \
            --from-literal=api-token='<GANDI-API-KEY>'

4. Grant permission for the service-account to access the secret holding the Gandi API key:

        kubectl apply -f rbac-gandi-credentials.yaml

5. Deploy this webhook (add `--dry-run` to inspect the rendered image):

        helm install cert-manager-webhook-gandi \
            --namespace cert-manager \
            --set image.repository=cert-manager-webhook-gandi \
            --debug \
            ./deploy/cert-manager-webhook-gandi

    * Check the logs

            kubectl get pods -n cert-manager
            kubectl logs -n cert-manager cert-manager-webhook-gandi-XYZ

6. Create a staging issuer (email addresses which end with example.com are forbidden):

        cat << EOF | sed 's/invalid@example.com/your-email/' | kubectl apply -f -
         apiVersion: cert-manager.io/v1alpha2
         kind: Issuer
         metadata:
           name: letsencrypt-staging
         spec:
           acme:
             # The ACME server URL
             server: https://acme-staging-v02.api.letsencrypt.org/directory

             # Email address used for ACME registration
             email: invalid@example.com

             # Name of a secret used to store the ACME account private key
             privateKeySecretRef:
               name: letsencrypt-staging

             solvers:
             - dns01:
                 webhook:
                   groupName: certmanager.webhook.gandi
                   solverName: gandi
                   config:
                     apiKeySecretRef:
                       key: api-token
                       name: gandi-credentials
        EOF

7. Check status of the issuer

        kubectl describe issuer letsencrypt-staging

8. Issue a certificate for the `$DOMAIN`

        cat << EOF | sed 's/example-com/$DOMAIN/' | kubectl apply -f -
        apiVersion: cert-manager.io/v1alpha2
        kind: Certificate
        metadata:
          name: example-com
        spec:
          commonName: example-com
          dnsNames:
          - example-com
          issuerRef:
            name: letsencrypt-staging
          secretName: example-com-tls
        EOF

9. Check the status of the certificate:

        kubectl describe certificate $NAME

99. Uninstall this webhook

        helm uninstall cert-manager-webhook-gandi --namespace cert-manager


## Development
Note: If some tool (IDE or build process) fails resolving a dependency, it may be the cause that a indirect dependency uses `bzr` for versioning. In such a case it may help to put the `bzr` binary into `$PATH` or `$GOPATH/bin`.


## Conformance test
Please note that the test is not a typical unit or integration test. Instead it invokes the web hook in a Kubernetes-like environment which asks the web hook to really call the DNS provider (.i.e. Gandi). It attempts to create an `TXT` entry like `cert-manager-dns01-tests.example.com`, verifies the presence of the entry via Google DNS. Finally it removes the entry by calling the cleanup method of web hook.

Note: Replace the string `darwin` in the URL below with a OS matching your system (e.g. `linux`).

As said above, the conformance test can only be run against the real Gandi API. Therefore you *must* have a Gandi account, a domain and an API key.


    cp testdata/gandi/api-key.yaml.sample testdata/gandi/api-key.yaml
    echo -n $YOUR_GANDI_API_KEY | base64 | pbcopy # or xclip
    $EDITOR testdata/gandi/api-key.yaml
    ./scripts/fetch-test-binaries.sh
    TEST_ZONE_NAME=example.com. go test -v .


## Thanks
This implementation would have been impossible without the excellent  [cert-manager-webhook-softlayer](https://github.com/cgroschupp/cert-manager-webhook-softlayer). Thank you for providing the missing peaces.


[cert-manager]: https://cert-manager.io/
[Gandi]: https://gandi.net/
[Gandi LiveDNS API]: https://doc.livedns.gandi.net
[Kubernetes]: https://kubernetes.io/
