FROM node:8.9.0

WORKDIR /app

ENV NODE_ENV=production
#ADD package.json yarn.lock .npmrc /app/
#RUN unset NODE_ENV; yarn install

ADD . /app/

#RUN yarn build
#CMD npx postgraphile -c postgres:///c3data -w -h 0.0.0.0 -p 5000

EXPOSE 5000
