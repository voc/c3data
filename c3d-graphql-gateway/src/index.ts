import { createServer } from 'http';

import express, { Request, Response } from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import { ApolloServer } from 'apollo-server-express';
import { execute, subscribe, GraphQLSchema } from 'graphql';
import { SubscriptionServer } from 'subscriptions-transport-ws';

//import persistentQueries from './util/persistentQueries';
import { graphiqlExpress } from './util/graphiql';
import mergeSchemas from './schema';
//import schemaDirectives from './schema/directives';
//const schemaDirectives = [];


const isDevelopment = true;
const app = express();

async function run() {
	app.use('*', cors({ origin: '*' }));

	const graphqlPath = '/graphql';
	const schema: GraphQLSchema = await mergeSchemas();

	// setup directives
	//SchemaDirectiveVisitor.visitSchemaDirectives(schema, schemaDirectives);

	const port = process.env.PORT || 5000;
	const playgroundOptions: any = isDevelopment
			? {
				endpoint: graphqlPath,
				subscriptionEndpoint: `ws://localhost:${port}/subscriptions`,
				settings: {
					// Force setting, workaround: https://github.com/prisma/graphql-playground/issues/790
					'editor.theme': 'dark',
					'editor.cursorShape': 'line', // possible values: 'line', 'block', 'underline'
				},
			  }
			: false;

	// see https://www.apollographql.com/docs/apollo-server/api/apollo-server.html
	const apolloServer = new ApolloServer({
		schema,
		context: ({ req, res }: { req: Request; res: Response }) => ({ req, res }),
		debug: isDevelopment,
		introspection: isDevelopment,
		playground: playgroundOptions,
	});

	app.use(graphqlPath, bodyParser.json()); //, persistentQueries);

	// still provide old GraphiQL interface
	if (isDevelopment) {
		app.use('/graphiql', graphiqlExpress({ endpointURL: '/graphql' }));
	}

	apolloServer.applyMiddleware({ app, path: graphqlPath });

	const server = createServer(app);
	server.listen(port, () => {
		console.log(`graphql gateway running on port ${port}`);

		new SubscriptionServer({ execute, subscribe, schema }, { server, path: '/subscriptions' });
	});
}
run();