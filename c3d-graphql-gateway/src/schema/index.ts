import { GraphQLSchema, } from 'graphql';
import { mergeSchemas, transformSchema, FilterRootFields, RenameTypes, RenameRootFields } from 'apollo-server';

import remoteSchema from '../util/remoteSchema'

export default async (): Promise<GraphQLSchema> => {


	const schemaLinkTypeDefs = null;

	const voctoweb = await remoteSchema('http://localhost:3000');
	const postgraphile = await remoteSchema('http://localhost:3001');
	const wiki = await remoteSchema('https://c3voc.de/wiki/graphql.php');

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