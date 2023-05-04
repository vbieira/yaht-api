# Yet Another Habits Tracker - API

## Requirements

Please ensure you are using Docker Compose V2. This project relies on the docker compose command, not the previous docker-compose standalone program.

https://docs.docker.com/compose/#compose-v2-and-the-new-docker-compose-command

Check your docker compose version with:

```sh
$ docker compose version # => Docker Compose version v2.10.2
```

## Initial setup

```sh
$ cp .env.sample .env
$ docker compose build
$ docker compose run --rm api bin/rails db:setup
```

## Running the Rails API

```sh
$ docker compose up
```
