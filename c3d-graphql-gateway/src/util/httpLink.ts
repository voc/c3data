import { ApolloLink, GraphQLRequest } from 'apollo-link';
import { HttpLink } from 'apollo-link-http';
import { HTTPLinkDataloader, HttpOptions } from 'http-link-dataloader';
import { setContext } from 'apollo-link-context';
import fetch from 'cross-fetch';

// forward the given headers to HttpLink request
const headerForwarder = setContext((operation: GraphQLRequest, prevContext: any) => ({
	headers: {
		...prevContext.headers,
		'user-agent': `c3data (gateway:${process.env.branch})`,
	},
}));

const createHttpLink = (opts: HttpOptions, batching: boolean = false) => {
	const httpLink = batching ? new HTTPLinkDataloader(opts) : new HttpLink({fetch, ...opts}) ;
	return ApolloLink.from([ headerForwarder, httpLink ]);
};

export default createHttpLink;
