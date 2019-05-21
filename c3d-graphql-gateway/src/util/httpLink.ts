import { ApolloLink, GraphQLRequest } from 'apollo-link';
import { setContext } from 'apollo-link-context';
import { HTTPLinkDataloader, HttpOptions } from 'http-link-dataloader';


// forward the given headers to HttpLink request
const headerForwarder = setContext((operation: GraphQLRequest, prevContext: any) => ({
	headers: {
		...prevContext.headers,
		'user-agent': `c3data (gateway:${process.env.branch})`,
	},
}));

const createHttpLink = (opts: HttpOptions) => {
	const httpLink = new HTTPLinkDataloader(opts);
	return ApolloLink.from([ headerForwarder, httpLink ]);
};

export default createHttpLink;
