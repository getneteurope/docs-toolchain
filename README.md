<h1 align="center">
  <a href="https://undraw.co/"><img src="logo/landing_page.svg" alt="Docs Toolchain Logo"></a>
</h1>

# docs-toolchain
Toolchain for TecDoc managed documentation repositories

<div align="center">
  
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/wirecard/docs-toolchain/Testing?style=for-the-badge)](https://github.com/wirecard/docs-toolchain/actions)   [![GitHub Issues](https://img.shields.io/github/issues-raw/wirecard/docs-toolchain?style=for-the-badge)](https://github.com/wirecard/docs-toolchain/issues)  [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](http://makeapullrequest.com)

[![Built with Ruby](https://forthebadge.com/images/badges/made-with-ruby.svg)](https://forthebadge.com) [![Built with Science](https://forthebadge.com/images/badges/built-with-science.svg)](https://forthebadge.com) [![forthebadge](https://forthebadge.com/images/badges/built-with-love.svg)](https://forthebadge.com) [![Uses Badges](https://forthebadge.com/images/badges/uses-badges.svg)](https://forthebadge.com)

</div>


## Disclaimer

Under heavy development, everything is subject to change and most likely will not be up-to-date!


## Stages
The toolchain is designed to run through different stages, that have specific responsibilities:
1. **setup**: install required dependencies
2. **test**:
    * create info files (like git information, e.g. branch, commit author, last edited by, etc.)
    * validate all configuration files
    * test the current commit with:
        * predefined tests by the toolchain (`lib/extensions.d/`)
        * custom tests (`${CONTENT_REPO}/extensions.d/`)
        * abort the build if necessary
    * keep a log of all events which will be used in the notify stage
3. **build**:
    * invoke asciidoctor (with multipage converter)
    * create Table of Content
    * create search index (Lunr)
    * `DEBUG` build for local testing:
        * **DO NOT** minify and combine Javascript files
        * **DO NOT** minify CSS
        * passthrough as `:debug:` to asciidoctor
    * frontend functionality:
        * `header.js.d/`: scripts that need to be loaded at the beginning, will be combined to `header.js` and minified
        * `footer.js.d/`: scripts that need to be loaded at the end, will be combined to `footer.js` and minified
    * run custom build scripts `build.d/*.sh`
4. **post**:
    * post processing for additional features like
        * lunr.js
        * table of content changes
        * trigger translation
5. **deploy**:
    * [wirecard/s3-deploy](https://github.com/wirecard/s3-deploy)
    * [crazy-max/ghaction-github-pages](https://github.com/crazy-max/ghaction-github-pages)
    * required variables, see [Configuration/Secret/AWS](#Secret)
6. **notify**:
    * send Slack message stating the fail status and a description if the build failed, see [Configuration/Secret/Slack](#Secret)

## Configuration
There are some variables that need to be secret, while others can be public.
Configuration files are public.

### Secret
* **AWS**
    * `AWS_ACCESS_KEY_ID`
    * `AWS_SECRET_ACCESS_KEY`
    * `AWS_REGION`
    * `AWS_S3_BUCKET`
* **Slack**
    * `SLACK_TOKEN` (Optional)

### Public
#### Variables

#### Files
Configuration files:
* `config/settings.json`: general settings
* `config/log.json`: logging specific settings
* `config/invalid-patterns.json`
* `config/error-types.json`: lists all warning/error types with a unique string ID, a unique error code (grouped like HTTP codes), and a format string like error message.
* `static/privacy-policy.(txt|adoc)`


## Utilities
The **test** and **build** stages produce `/tmp/errors.json`, a central file containing all warnings and errors that occured during the **test** or **build** stages.
Warnings and errors are defined in `error-types.json` and further ignored or interpreted as errors according to `settings.json`.
`slack-notifiy.py` sends these warnings and/or errors (if there are any) to a Slack channel, defined in the secret variable `SLACK_TOKEN`.
Otherwise

## Run

To run the toolchain locally, or run the unit tests, the following requirements must be met:
* bats
* Ruby 2.x
* Python 3
* Node.js 13
* installed dependencies

In order to install dependencies, run the following at the root of the project:
```bash
export TOOLCHAIN_PATH="$(pwd)"
bash stages/setup/setup_main.sh
```

