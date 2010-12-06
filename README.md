# salesforce-sync

Export Salesforce objects into a local database.

## Changelog

### 0.0.4

The syncs table schema has changed in this version. Assuming your
table is named `_salesforce_syncs` (the default), execute the
following statements:
   
    ALTER TABLE _salesforce_syncs RENAME COLUMN started_at TO timestamp;
    ALTER TABLE _salesforce_syncs ADD COLUMN created_at TIMESTAMP;
    UPDATE _salesforce_syncs SET created_at = (SELECT statement_timestamp() - (interval '1 hour' * ((SELECT MAX(id) FROM _salesforce_syncs LIMIT 1) - id)));

## Copyright

Copyright (c) 2010 Christof Spies, Moritz Heidkamp. See LICENSE.txt
for further details.
