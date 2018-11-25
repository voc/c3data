FROM node:8.9.0

WORKDIR /app

ENV NODE_ENV=production
ADD package.json yarn.lock /app/
RUN unset NODE_ENV; yarn install

ADD . /app/

RUN yarn build
CMD yarn start
