ARG ARGOCD_VERSION
FROM quay.io/argoproj/argocd:$ARGOCD_VERSION
ARG SOPS_VERSION
ARG VALS_VERSION
ARG HELM_SECRETS_VERSION
ARG KUBECTL_VERSION
ARG HELMFILE_VERSION
ARG HELM_GIT_VERSION
ARG YQ_VERSION
# vals or sops
ENV HELM_SECRETS_BACKEND="sops" \
    HELM_SECRETS_HELM_PATH=/usr/local/bin/helm \
    HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false \
    HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false \
    HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false \
    HELM_SECRETS_WRAPPER_ENABLED=true \
    HELM_SECRETS_DECRYPT_SECRETS_IN_TMP_DIR=true \
    HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/" \
    KUSTOMIZE_BIN=/usr/local/bin/kustomize

USER root

RUN apt-get update && apt-get install -y \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl -fsSL https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl \
    && curl -fsSL https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64 \
    -o /usr/local/bin/sops && chmod +x /usr/local/bin/sops \
    && curl -fsSL https://github.com/helmfile/vals/releases/download/v${VALS_VERSION}/vals_${VALS_VERSION}_linux_amd64.tar.gz \
    | tar xzf - -C /usr/local/bin/ vals && chmod +x /usr/local/bin/vals \
    && curl -fsSL https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz \
    | tar xzf - -C /usr/local/bin helmfile && chmod +x /usr/local/bin/helmfile \
    && ln -sf "$(helm env HELM_PLUGINS)/helm-secrets/scripts/wrapper/helm.sh" /usr/local/sbin/helm \
    && curl -fsSLo /usr/local/sbin/kustomize https://raw.githubusercontent.com/joelee2012/skustomize/main/skustomize \
    && chmod +x /usr/local/sbin/kustomize \
    && curl -fsSL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

USER $ARGOCD_USER_ID

RUN helm plugin install --version ${HELM_SECRETS_VERSION} https://github.com/jkroepke/helm-secrets \
    && helm plugin install --version ${HELM_GIT_VERSION} https://github.com/aslafy-z/helm-git \
    && git config --global credential.helper store
