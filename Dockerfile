FROM ruby:2.6.5

WORKDIR /var/app
COPY Gemfile .
RUN bundle install

CMD ["bash"]
