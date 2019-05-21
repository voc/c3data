import * as express from 'express';
import * as url from 'url';
import { print, parse } from 'graphql';
import * as GraphiQL from 'apollo-server-module-graphiql';


export interface ExpressGraphiQLOptionsFunction {
	(req?: express.Request): GraphiQL.GraphiQLData | Promise<GraphiQL.GraphiQLData>;
}

/* This middleware returns the html for the GraphiQL interactive query UI
 *
 * GraphiQLData arguments
 *
 * - endpointURL: the relative or absolute URL for the endpoint which GraphiQL will make queries to
 * - (optional) query: the GraphQL query to pre-fill in the GraphiQL UI
 * - (optional) variables: a JS object of variables to pre-fill in the GraphiQL UI
 * - (optional) operationName: the operationName to pre-fill in the GraphiQL UI
 * - (optional) result: the result of the query to pre-fill in the GraphiQL UI
 */

export function graphiqlExpress(options: GraphiQL.GraphiQLData | ExpressGraphiQLOptionsFunction) {
	const graphiqlHandler = (req: express.Request, res: express.Response, next: Function) => {
		let query: any = req.url && url.parse(req.url, true).query;
		if ('query' in query) {
			// prettify query from url
			try {
				query.query = print(parse(query.query));
			}
			catch {}
		}
		GraphiQL.resolveGraphiQLString(query, options, req).then(
			(graphiqlString: any) => {
				res.setHeader('Content-Type', 'text/html');
				res.write(graphiqlString);
				res.end();
			},
			(error: any) => next(error),
		);
	};

	return graphiqlHandler;
}
