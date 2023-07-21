ARG ARGOCD_VERSION
FROM quay.io/argoproj/argocd:$ARGOCD_VERSION
ARG SOPS_VERSION
ARG VALS_VERSION
ARG HELM_SECRETS_VERSION
ARG KUBECTL_VERSION
ARG HELMFILE_VERSION
ARG HELM_GIT_VERSION
# vals or sops
ENV HELM_SECRETS_BACKEND="sops" \
    HELM_SECRETS_HELM_PATH=/usr/local/bin/helm \
    HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/" \
    HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false \
    HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false \
    HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false \
    HELM_SECRETS_WRAPPER_ENABLED=true

USER root

RUN apt-get update && apt-get install -y \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl -fsSL https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux \
    -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops \
    && curl -fsSL https://github.com/helmfile/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_amd64.tar.gz \
    | tar xzf - -C /usr/local/bin/ vals && chmod +x /usr/local/bin/vals \
    && curl -fsSL https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz \
    | tar xzf - -C /usr/local/bin helmfile && chmod +x /usr/local/bin/helmfile \
    && ln -sf "$(helm env HELM_PLUGINS)/helm-secrets/scripts/wrapper/helm.sh" /usr/local/sbin/helm

USER $ARGOCD_USER_ID

RUN helm plugin install --version ${HELM_SECRETS_VERSION} https://github.com/jkroepke/helm-secrets \
    && helm plugin install --version ${HELM_GIT_VERSION} https://github.com/aslafy-z/helm-git \
    && sed -i '2iHELM_SECRETS_DEC_PREFIX=$(echo "$*" | sha256sum | cut -d " "  -f1)\nexport HELM_SECRETS_DEC_PREFIX' "$(helm secrets dir)/scripts/wrapper/helm.sh" \
    && git config --global credential.helper store
