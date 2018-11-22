import { MigrationBuilder } from 'node-pg-migrate';
import fs from 'fs';

export const up = (pgm: MigrationBuilder) => {
    pgm.sql(fs.readFileSync('schema/computed_properties/events.pgsql', { encoding: 'utf8' }));
};

export const down = {};
