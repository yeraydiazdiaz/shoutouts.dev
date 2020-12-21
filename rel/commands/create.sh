#!/bin/sh

release_ctl eval --mfa "Shoutouts.ReleaseTasks.create/1" --argv -- "$@"
