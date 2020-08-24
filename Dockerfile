FROM registry.access.redhat.com/ubi8 as base

ENV app_root=/opt/manageiq/amazon-smartstate

RUN dnf -y --disableplugin=subscription-manager module enable ruby:2.6

######################
FROM base as gemset

RUN dnf -y --disableplugin=subscription-manager install --setopt=tsflags=nodocs \
      gcc               \
      gcc-c++           \
      git-core          \
      make              \
      libxml2-devel     \
      libxslt-devel     \
      redhat-rpm-config \
      ruby-devel        \
      rubygem-bundler   \
      rubygems-devel && \
    dnf clean all

COPY container-assets/* ${app_root}/
WORKDIR ${app_root}

RUN echo 'gem: --no-ri --no-rdoc --no-document' > /root/.gemrc && \
    bundle config --local path gemset && \
    bundle config --local bin bin && \
    bundle install --jobs=8

######################
FROM base

RUN dnf -y --disableplugin=subscription-manager install --setopt=tsflags=nodocs \
      libxml2            \
      libxslt            \
      ruby               \
      rubygem-bundler && \
    dnf clean all

ENV PATH="${app_root}/bin:${PATH}"
COPY --from=gemset ${app_root} ${app_root}
WORKDIR ${app_root}

CMD bundle exec amazon_ssa_agent
