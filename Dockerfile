FROM ruby

EXPOSE 3030

RUN apt-get update \
    && apt-get upgrade -yq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /smashing
RUN gem install smashing

COPY entrypoint.sh /usr/local/sbin
ENTRYPOINT ["entrypoint.sh"]

CMD ["smashing", "start", "-p", "3030"]
