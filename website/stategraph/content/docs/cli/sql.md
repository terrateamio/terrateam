---
title: SQL Commands
description: Query your Terraform resources with SQL from the terminal, page through large results, and read the schema.
order: 4
---


The `stategraph sql` commands run SQL queries on your infrastructure from the command line, and show the SQL schema.

## Commands

| Command | Description |
|---------|-------------|
| `stategraph sql query` | Run a SQL query |
| `stategraph sql schema` | Show the tables, columns, and row limits |

## stategraph sql query

`stategraph query` is a top-level alias.

```bash
stategraph sql query <query>
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<query>` | Yes | SQL query string |

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--format` | No | Output format: `table` (default), `json` for `jq`, or `simple` (one value per line, no headers) |
| `--paginate` | No | Read every page of the result, not only the first. Requires an `ORDER BY`. |

### Result size and pagination

A query returns one page:

- Without a `LIMIT`, 20 rows (`default_limit`).
- With a `LIMIT`, that many rows, up to the server maximum of 1000 (`max_limit`).

`stategraph sql schema` shows both limits. When more rows match, the command prints a note to stderr, so piping stdout to `jq` still works.

To read the whole result, raise the `LIMIT`:

```bash
stategraph sql query "SELECT address FROM resources LIMIT 1000"
```

Or add `--paginate` to follow the pagination links to the end of the result. With `--paginate`, `LIMIT` sets the page size, not the total:

```bash
stategraph sql query --paginate "SELECT address FROM resources ORDER BY address"
```

`--paginate` needs an `ORDER BY` over plain column names that the query also selects, so that the server can build a cursor. Otherwise, the command fails with the reason and returns no partial result:

```console
$ stategraph sql query --paginate "SELECT address FROM resources"
Error: --paginate cannot page this query.
The query has no ORDER BY clause.

To fix: add an ORDER BY over a column that orders the rows uniquely, e.g. 'ORDER BY id'.
```

Without `--paginate`, add a `LIMIT` when you need a predictable result size.

### Scoping a query to one state

A query covers all states in the tenant. To query one state, add a `state_id` predicate to the `WHERE` clause. The `states` table lists the state IDs:

```bash
stategraph sql query "SELECT id, name, workspace FROM states"
stategraph sql query "SELECT address FROM resources WHERE state_id = '<state-id>'"
```

The predicate works with `ORDER BY`, `LIMIT`, and `--paginate`:

```bash
stategraph sql query --paginate \
  "SELECT address FROM resources WHERE state_id = '<state-id>' ORDER BY address"
```

### Example

```bash
stategraph sql query "SELECT type, count(*) AS total FROM resources GROUP BY type" --format json
```

Output:

```json
[
  { "type": "aws_instance", "total": 20 },
  { "type": "aws_security_group", "total": 15 },
  { "type": "aws_subnet", "total": 6 }
]
```

### More Queries

```bash
# Count total instances
stategraph sql query "SELECT count(*) FROM instances"

# List all resource types with counts (count is reserved; alias as total and order by the expression)
stategraph sql query "SELECT type, count(*) as total FROM resources GROUP BY type ORDER BY count(*) DESC"

# Find resources by type (type lives on the resources table)
stategraph sql query "SELECT address FROM resources WHERE type = 'aws_instance'"

# Scope a query to one state
stategraph sql query "SELECT count(*) AS total FROM resources WHERE state_id = '<state-id>'"
```

### SQL Syntax Notes

Stategraph SQL supports a subset of standard SQL, including:

- `INNER`, `LEFT`, and `RIGHT` joins with `ON` conditions
- Table aliases: `FROM resources AS r` lets you write `r.type`
- Column aliases: `count(*) as total`
- CTEs: `WITH name AS (...)`, including `UNION`
- `ORDER BY`, for example `ORDER BY type ASC`
- `LIKE`, `ILIKE`, `NOT LIKE`, and `NOT ILIKE`, with the `%` and `_` wildcards

Queries cannot contain comments (`--` or `/* */`).

## stategraph sql schema

```bash
stategraph sql schema --format json
```

By default, `sql schema` prints one row per column, with its table and type. `--format json` shows the columns of each table with their PostgreSQL types, and the row limits:

```json
{
  "default_limit": 20,
  "max_limit": 1000,
  "tables": {
    "instances": {
      "columns": {
        "address": { "type": "text" },
        "attributes": { "type": "jsonb" },
        "dependencies": { "type": "text[]" },
        "resource_address": { "type": "text" },
        "state_id": { "type": "uuid" }
      }
    },
    "resources": {
      "columns": {
        "address": { "type": "text" },
        "module": { "type": "text" },
        "state_id": { "type": "uuid" },
        "type": { "type": "text" }
      }
    },
    "states": {
      "columns": {
        "id": { "type": "uuid" },
        "name": { "type": "text" },
        "group_id": { "type": "uuid" },
        "workspace": { "type": "text" }
      }
    }
  }
}
```

The example shows only some tables. When Orchestration is enabled, you can also query its GitHub and GitLab data for your tenant: runs, pull requests, gates, drift schedules, and pull request stacks.

## Scripting Examples

### Export query results to CSV

```bash
stategraph sql query "SELECT address, type FROM resources" --format json | \
  jq -r '.[] | [.address, .type] | @csv' > resources.csv
```

### Count resources and format output

```bash
stategraph sql query "SELECT type, count(*) AS total FROM resources GROUP BY type" --format json | \
  jq -r '.[] | "\(.type): \(.total)"'
```

### Generate report

```bash
#!/bin/bash
echo "Infrastructure Report"
echo "===================="
echo ""
echo "Total resources:"
stategraph sql query "SELECT count(*) AS total FROM instances" --format json | jq -r '.[0].total'
echo ""
echo "By type:"
stategraph sql query "SELECT type, count(*) AS total FROM resources GROUP BY type" --format json | \
  jq -r '.[] | "  \(.type): \(.total)"'
```

## Error Handling

### Syntax Errors

```bash
stategraph sql query "SELEC * FROM instances"
# Exit code: 1
# Error: QUERY_ERR (<parser message>)
```

### Unknown Columns

```bash
stategraph sql query "SELECT foo FROM instances"
# Exit code: 1
# Error: Unknown column 'foo'.
#
# To fix: run 'stategraph sql schema' to see available columns for each table.
```

## Tips

- Quote each query, so that the shell does not interpret it.
- When you join tables, qualify columns with a table name or alias (`r.type`).

## Next Steps

- [Query](/docs/infrastructure-as-a-database/query/query): the full SQL documentation.
- [SQL Syntax Reference](/docs/reference/sql-syntax): the complete grammar.
- [Dashboards](/docs/infrastructure-as-a-database/query/dashboards): save queries in the console.
