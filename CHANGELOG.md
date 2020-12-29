# Changelog

## [20.1.1] - 2020-12-29

- Config update to migrate to GitHub OAuth App:
    - Narrows permissions when users log in for the first time, some users
    reported the "Act on your behalf" message was a blocking issue.
    - Users that logged in with the GitHub App will need to log in again and
    grant access to the OAuth App. The previous GitHub App will be deleted
    after one week.

## [20.1.1] - 2020-12-26

- Initial beta release.
