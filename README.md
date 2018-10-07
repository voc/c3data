# c3data


## setup

```
  docker-compose up postgres
  docker exec -i c3data_postgres_1 psql c3data < c3d-graphql/schema.sql
```

## usage

```
  docker-compose up c3d-graphql
```