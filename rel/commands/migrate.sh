#!/bin/sh

release_ctl eval --mfa "Shoutouts.ReleaseTasks.migrate/1" --argv -- "$@"
