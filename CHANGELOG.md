# Changelog

## Unreleased

- Reduce required account longevity to 3 months.

## [21.2.5] - 2021-05-05

- Add Select All/None to add projects.
- Show error when attempting to add projects without selecting any.
- Improve error handling in GH client.
- Add 3 second timeout to Tesla client.

## [21.2.4] - 2021-05-03

- Fix badge endpoint returning 404 if project has no shoutouts.
- Reduce OAuth scopes to just user name and email.

## [21.2.3] - 2021-05-03

- Fix selecting null project language on project summary.

## [21.2.2] - 2021-05-03

- Fix title tags not updating across live views.

## [21.2.1] - 2021-04-27

- Add weekly task to email project owners notifying them of new shoutouts.
- Add Sponsors page.

## [21.2.0] - 2021-04-19

- Added ability for any user to register a project, once registered the project
is "unclaimed". Users will be able to add shoutouts to an unclaimed project and
owners can log in and claim them to manage its shoutouts.

## [21.1.9] - 2021-04-08

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
