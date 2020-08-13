FROM tesseractshadow/tesseract4re

COPY . /usr/src/app
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
        build-essential \
        gosu \
        liblzma-dev \
        patch \
        ruby \
        ruby-dev \
        zlib1g-dev && \
    useradd app && \
    gem install bundler && \
    bundle install && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["ruby"]
