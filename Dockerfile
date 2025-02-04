FROM registry.access.redhat.com/ubi9 as base

ENV app_root=/opt/manageiq/amazon-smartstate

RUN dnf -y --disableplugin=subscription-manager module enable ruby:3.1 && \
    dnf -y --disableplugin=subscription-manager install --setopt=tsflags=nodocs \
      libxml2 \
      libxslt \
      ruby && \
    dnf clean all && \
    rm -rf /var/cache/dnf && \
    echo 'gem: --no-ri --no-rdoc --no-document' > /root/.gemrc && \
    gem install bundler

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
      rubygems-devel && \
    dnf clean all

COPY container-assets/* ${app_root}/

WORKDIR ${app_root}

RUN bundle config --local path gemset && \
    bundle config --local bin bin && \
    bundle install --jobs=8

######################
FROM base

ENV PATH="${app_root}/bin:${PATH}"
COPY --from=gemset ${app_root} ${app_root}
WORKDIR ${app_root}

CMD bundle exec amazon_ssa_agent
