import createHttpLink from './httpLink';
import { introspectSchema, makeRemoteExecutableSchema } from 'graphql-tools';

export default async (uri: string, batching: boolean = false) => {
    const link = createHttpLink({ uri }, batching);
	const schema = await introspectSchema(link);
	const executableSchema = makeRemoteExecutableSchema({
		schema,
		link,
	});

	return executableSchema;
};
