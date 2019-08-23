import { GraphQLSchema, } from 'graphql';
import { weaveSchemas } from 'graphql-weaver';

export default async (): Promise<GraphQLSchema> => {

	const schema: GraphQLSchema = await weaveSchemas({
		endpoints: [{
			namespace: 'media',
			typePrefix: 'Media',
			url: process.env.VOCTOWEB_URL || 'https://media.ccc.de/graphql',
		}, {
			namespace: 'wiki',
			typePrefix: 'Wiki',
			url: process.env.WIKI_URL || 'https://c3voc.de/wiki/graphql.php',
		}, {
			namespace: 'schedule',
			typePrefix: 'Schedule',
			url: process.env.C3D_URL || 'https://data.c3voc.de/graphql',
		}]
	})

	return schema;
}