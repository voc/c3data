FROM node:8.9.0

# ARGUMENT DEFINITION
ARG INSTALL_WATCHMAN=false

WORKDIR /app

# INSTALL WATCHMAN
ADD ./scripts /app/scripts/
RUN if [ "$INSTALL_WATCHMAN" = "true" ] ; then ./scripts/installWatchman.sh ; else echo "watchman installation skipped" ; fi

# INSTALL NODEJS DEPENDENCIES
ENV NODE_ENV=production
ADD package.json yarn.lock /app/
RUN unset NODE_ENV; yarn install

ADD . /app/

RUN yarn build
CMD yarn start
