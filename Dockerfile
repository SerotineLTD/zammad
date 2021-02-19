FROM ruby:2.4.4

RUN bundle config --global frozen 1

WORKDIR /opt/zammad

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["./script/docker-start"]
