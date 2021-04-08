# Changelog

## Unreleased

- Added buttons to shoutout carrousel in home page.

## [21.1.8] - 2021-04-07

- Added latest shoutout from most popular projects in home page.

## [21.1.7] - 2021-03-28

- Added background task to update projects.

## [21.1.6] - 2021-03-20

- Dashboard endpoint available only in dev.

## [21.1.5] - 2021-01-30

- Fix AppSignal configuration.
- Render colon emojis on search results.

## [21.1.4] - 2021-01-16

- Add AppSignal. Thanks!

## [21.1.3] - 2021-01-04

- Render :colon-emojis: on descriptions and shoutouts.

## [21.1.2] - 2021-01-01

- Fix CSP for avatars in production.
- Add badge FAQ section.

## [21.1.1] - 2021-01-01

- Remove emoji and markup limitation on shoutouts.
- Add Content Security Policy.

## [20.1.1] - 2020-12-29

- Config update to migrate to GitHub OAuth App:
    - Narrows permissions when users log in for the first time, some users
    reported the "Act on your behalf" message was a blocking issue.
    - Users that logged in with the GitHub App will need to log in again and
    grant access to the OAuth App. The previous GitHub App will be deleted
    after one week.

## [20.1.1] - 2020-12-26

- Initial beta release.
