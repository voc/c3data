const express = require("express");
const { postgraphile } = require("postgraphile");
const ConnectionFilterPlugin = require("postgraphile-plugin-connection-filter");
const SimplifyInflectorPlugin = require("@graphile-contrib/pg-simplify-inflector");
const NestedMutationsPlugin = require('postgraphile-plugin-nested-mutations');

const app = express();

app.use(
	postgraphile(process.env.DATABASE_URL || "postgres:///c3data", "public", {
		graphiql: true,
		enhanceGraphiql: true,
		appendPlugins: [ConnectionFilterPlugin, SimplifyInflectorPlugin, NestedMutationsPlugin],
		graphileBuildOptions: {
			// https://github.com/graphile-contrib/postgraphile-plugin-connection-filter#performance-and-security
			connectionFilterComputedColumns: false,
			connectionFilterSetofFunctions: false,
			connectionFilterLists: false
		},
		watchPg: true,
		disableQueryLog: process.env.NODE_ENV === 'development',
		//pgDefaultRole: "viewer"
	})
);

app.listen(process.env.PORT || 5000);