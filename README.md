# SNMPwatch

Tool for monitoring traffic information via SNMP and storing it to Postgres database.

## Depends on

Written in Ruby 1.8 and requires the following gems: `pg`, `snmp`. Database schema is provided in `schema.sql`.

## Operation

Invoked as a cronjob, this tool executes SNMP requests for each pair hostid:itemid in `watched_items` table of database and accumulates received traffic information in acculumate field of `history` table. In a nutshell, that's it.

## Status

Works for a 1.5+ year in a production environment. Sources are not touched since july 2011.

## Licencse

Copyright (c) 2011, 2012. Ilia Zhirov

Licensed under terms of [MIT license](http://www.opensource.org/licenses/mit-license.php).

Feel free to fork it, fix any bugs, add features, send me a pull requests and so on. Bug reports are also welcome.
