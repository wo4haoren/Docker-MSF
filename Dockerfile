FROM ruby:2.6.5-alpine3.10 AS builder
LABEL maintainer="Rapid7"

ARG BUNDLER_ARGS="--jobs=8 --without development test coverage"
ENV APP_HOME=/usr/src/metasploit-framework
ENV BUNDLE_IGNORE_MESSAGES="true"
WORKDIR $APP_HOME

COPY Gemfile* metasploit-framework.gemspec Rakefile $APP_HOME/
COPY lib/metasploit/framework/version.rb $APP_HOME/lib/metasploit/framework/version.rb
COPY lib/metasploit/framework/rails_version_constraint.rb $APP_HOME/lib/metasploit/framework/rails_version_constraint.rb
COPY lib/msf/util/helper.rb $APP_HOME/lib/msf/util/helper.rb

RUN apk add --no-cache \
      autoconf \
      bison \
      build-base \
      ruby-dev \
      openssl-dev \
      readline-dev \
      sqlite-dev \
      postgresql-dev \
      libpcap-dev \
      libxml2-dev \
      libxslt-dev \
      yaml-dev \
      zlib-dev \
      ncurses-dev \
      git \
    && echo "gem: --no-document" > /etc/gemrc \
    && gem update --system 3.0.6 \
    && gem install pry \
    && bundle install --force --clean --no-cache --system $BUNDLER_ARGS \
    # temp fix for https://github.com/bundler/bundler/issues/6680
    && rm -rf /usr/local/bundle/cache \
    # needed so non root users can read content of the bundle
    && chmod -R a+r /usr/local/bundle


FROM ruby:2.6.5-alpine3.10
LABEL maintainer="Rapid7"

ENV APP_HOME=/usr/src/metasploit-framework
ENV NMAP_PRIVILEGED=""
ENV METASPLOIT_GROUP=metasploit

# used for the copy command
RUN addgroup -S $METASPLOIT_GROUP

RUN apk add --no-cache bash sqlite-libs nmap nmap-scripts nmap-nselibs postgresql-libs python python3 ncurses libcap su-exec screen postgresql vim patch less

RUN /usr/sbin/setcap cap_net_raw,cap_net_bind_service=+eip $(which ruby)
RUN /usr/sbin/setcap cap_net_raw,cap_net_bind_service=+eip $(which nmap)

COPY --from=builder /usr/local/bundle /usr/local/bundle
RUN chown -R root:metasploit /usr/local/bundle
COPY . $APP_HOME/
RUN chown -R root:metasploit $APP_HOME/
RUN chmod 664 $APP_HOME/Gemfile.lock

WORKDIR $APP_HOME

RUN if [[ ! -f $APP_HOME/msfdb ]] ; then wget -q https://raw.githubusercontent.com/rapid7/metasploit-framework/master/msfdb -O - | sed 's/bundle thin/bundle/' > $APP_HOME/msfdb ; fi
RUN chmod 755 msfdb && chown -R root:metasploit $APP_HOME/ \
    && mkdir /var/run/postgresql && chown postgres:postgres /var/run/postgresql \
	&& su-exec postgres $APP_HOME/msfdb init  --component database --use-defaults \
	&& echo -e "termcapinfo xterm* ti@:te@\ndefscrollback 100000" > /root/.screenrc \
    && echo -e "set mouse-=a" > /root/.vimrc \
    && ln -s $APP_HOME/msf* /usr/local/bin \
    && patch -i hashdump.patch modules/post/windows/gather/hashdump.rb \
    && patch -i smart_hashdump.patch modules/post/windows/gather/smart_hashdump.rb

VOLUME /home/msf
VOLUME /var/lib/postgresql/.msf4/

EXPOSE 443
EXPOSE 80

# we need this entrypoint to dynamically create a user
# matching the hosts UID and GID so we can mount something
# from the users home directory. If the IDs don't match
# it results in access denied errors.
ENTRYPOINT ["docker/entrypoint.sh"]

CMD ["./msfconsole", "-y", "config/database.yml"]
