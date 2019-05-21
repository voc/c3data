const express = require("express");
const pg = require("pg");
const { ApolloServer } = require("apollo-server");

const { makeSchemaAndPlugin } = require("postgraphile-apollo-server");

const ConnectionFilterPlugin = require("postgraphile-plugin-connection-filter");
const SimplifyInflectorPlugin = require("@graphile-contrib/pg-simplify-inflector");
const NestedMutationsPlugin = require('postgraphile-plugin-nested-mutations');
const UpsertPlugin = require('graphile-upsert-plugin');


const postGraphileOptions = {
  jwtSecret: process.env.JWT_SECRET || String(Math.random()),
  dynamicJson: true,
  graphiql: true,
  enhanceGraphiql: true,
  appendPlugins: [ConnectionFilterPlugin, SimplifyInflectorPlugin, NestedMutationsPlugin, UpsertPlugin],
  graphileBuildOptions: {
    // https://github.com/graphile-contrib/postgraphile-plugin-connection-filter#performance-and-security
    connectionFilterComputedColumns: false,
    connectionFilterSetofFunctions: false,
    connectionFilterLists: false
  },
  watchPg: true,
  disableQueryLog: process.env.NODE_ENV === 'development',
  //pgDefaultRole: "viewer"
};


const dbSchema = process.env.SCHEMA_NAMES
  ? process.env.SCHEMA_NAMES.split(",")
  : "public";

const pgPool = new pg.Pool({
  connectionString: process.env.DATABASE_URL || "postgres:///c3data"
});

async function main() {
  // See https://www.graphile.org/postgraphile/usage-schema/ for schema-only usage guidance
  const { postgraphileSchema, postgraphilePlugin } = await makeSchemaAndPlugin(
    pgPool,
    dbSchema,
    postGraphileOptions
  );

  // See https://www.apollographql.com/docs/apollo-server/api/apollo-server.html#ApolloServer
  const server = new ApolloServer({
    postgraphileSchema,
    plugins: [postgraphilePlugin]
  });

  const { url } = await server.listen(process.env.PORT || 5001);
  console.log(`🚀 Server ready at ${url}`);
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});