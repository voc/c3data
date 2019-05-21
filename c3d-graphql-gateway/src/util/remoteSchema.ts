import createHttpLink from './httpLink';
import { introspectSchema, makeRemoteExecutableSchema } from 'graphql-tools';

export default async (uri: String) => {
    const link = createHttpLink({ uri });
	const schema = await introspectSchema(link);
	const executableSchema = makeRemoteExecutableSchema({
		schema,
		link,
	});

	return executableSchema;
};
