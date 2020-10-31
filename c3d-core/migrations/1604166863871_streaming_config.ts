import { MigrationBuilder } from 'node-pg-migrate';
import fs from 'fs';

export const up = (pgm: MigrationBuilder) => {
    pgm.sql(`ALTER TABLE rooms ADD COLUMN streaming_config json;`);
    pgm.sql(`ALTER TABLE conferences 
        ADD COLUMN keywords text[], 
        ADD COLUMN organizer text, 
        ADD COLUMN streaming_config json;`);
    pgm.sql(fs.readFileSync('schema/triggers/after_change.pgsql', { encoding: 'utf8' }));
};

export const down = {};
