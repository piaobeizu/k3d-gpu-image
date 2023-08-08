ARG K3S_TAG="v1.22.1-k3s1"
FROM rancher/k3s:$K3S_TAG as k3s

FROM nvidia/cuda:11.2.0-cudnn8-devel-ubuntu20.04

ARG NVIDIA_CONTAINER_RUNTIME_VERSION
ENV NVIDIA_CONTAINER_RUNTIME_VERSION=$NVIDIA_CONTAINER_RUNTIME_VERSION

RUN ls -a

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && \
    apt-get -y install gnupg2 curl fuse3 stress

# Install NVIDIA Container Runtime
RUN curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | apt-key add -
RUN curl -s -L https://nvidia.github.io/nvidia-container-runtime/ubuntu18.04/nvidia-container-runtime.list | tee /etc/apt/sources.list.d/nvidia-container-runtime.list
RUN apt-get update && \
    apt-get -y install nvidia-container-runtime=${NVIDIA_CONTAINER_RUNTIME_VERSION}

COPY --from=k3s /bin /bin
COPY --from=k3s /etc /etc
COPY ./$K3S_TAG/containerd-shim /bin/containerd-shim
COPY ./$K3S_TAG/containerd-shim-runc-v1 /bin/containerd-shim-runc-v1

RUN chmod 1777 /tmp

# Provide custom containerd configuration to configure the nvidia-container-runtime
RUN mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/

COPY ./$K3S_TAG/config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl

# Deploy the nvidia driver plugin on startup
RUN mkdir -p /var/lib/rancher/k3s/server/manifests

COPY device-plugin-daemonset.yaml /var/lib/rancher/k3s/server/manifests/nvidia-device-plugin-daemonset.yaml
COPY device-plugin-daemonset2.yaml /var/lib/rancher/k3s/server/manifests/nvidia-device-plugin-daemonset2.yaml
COPY device-plugin-daemonset3.yaml /var/lib/rancher/k3s/server/manifests/nvidia-device-plugin-daemonset3.yaml
COPY device-plugin-daemonset4.yaml /var/lib/rancher/k3s/server/manifests/nvidia-device-plugin-daemonset4.yaml

VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log

ENV PATH="$PATH:/bin/aux"
ENV CRI_CONFIG_FILE=/var/lib/rancher/k3s/agent/etc/crictl.yaml

ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]