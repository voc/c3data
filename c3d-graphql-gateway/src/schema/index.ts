import { GraphQLSchema, } from 'graphql';
import { mergeSchemas, transformSchema, FilterRootFields, RenameTypes, RenameRootFields } from 'apollo-server';

import remoteSchema from '../util/remoteSchema'

export default async (): Promise<GraphQLSchema> => {


	const schemaLinkTypeDefs = null;

	const voctoweb = await remoteSchema(process.env.VOCTOWEB_URL || 'https://media.ccc.de/graphql');
	const postgraphile = await remoteSchema(process.env.C3D_URL || 'https://data.c3voc.de/graphql');
	const wiki = await remoteSchema(process.env.WIKI_URL || 'https://c3voc.de/wiki/graphql.php');

	const schemas: GraphQLSchema[] = [
		voctoweb,
		postgraphile,
		wiki,
		schemaLinkTypeDefs,
	].filter((x: GraphQLSchema | null) => x !== null) as GraphQLSchema[];

	const mergedSchema = mergeSchemas({
		schemas,
		resolvers: {
			Query: {}
		}
	});

	return mergedSchema;
}