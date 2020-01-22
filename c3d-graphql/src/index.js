const express = require("express");
const { postgraphile } = require("postgraphile");
const ConnectionFilterPlugin = require("postgraphile-plugin-connection-filter");
const SimplifyInflectorPlugin = require("@graphile-contrib/pg-simplify-inflector");
const NestedMutationsPlugin = require('postgraphile-plugin-nested-mutations');
const UpsertPlugin = require('graphile-upsert-plugin');

// TODO: Combine Nested Mutations with Upsert, c.f. https://github.com/mlipscombe/postgraphile-plugin-nested-mutations/issues/13

const app = express();

app.use(
	postgraphile(process.env.DATABASE_URL || "postgres:///c3data", "public", {
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
		disableQueryLog: process.env.NODE_ENV !== 'development',
		pgDefaultRole: process.env.NODE_ENV === 'development' ? 'graphql' : 'viewer'
	})
);

const port = process.env.PORT || 5001
app.listen(port, () => {
	console.log(`=> server running at http://localhost:${port}/graphiql`);
});
