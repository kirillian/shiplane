# Build Base image
FROM kirillian2/rails:1.2.1 as base

RUN apt-get update -qq && apt-get install -y cmake

ARG APP_NAME
ENV APP_PATH /var/www/$APP_NAME
RUN mkdir -p $APP_PATH

# Build intermediate
FROM base as intermediate

WORKDIR $APP_PATH

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build Development image
FROM base as development

COPY --from=intermediate $APP_PATH $APP_PATH

WORKDIR $APP_PATH

ARG GITHUB_TOKEN
RUN git config --global url."https://$GITHUB_TOKEN:@github.com/".insteadOf "https://github.com/"
RUN git config --global --add url."https://$GITHUB_TOKEN:@github.com/".insteadOf "ssh://git@github.com/"
