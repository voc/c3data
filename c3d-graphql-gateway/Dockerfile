FROM node:12.3

WORKDIR /app

# INSTALL NODEJS DEPENDENCIES
ENV NODE_ENV=production
ADD package.json yarn.lock /app/
RUN unset NODE_ENV; yarn install

ADD . /app/

RUN yarn build
CMD yarn start
