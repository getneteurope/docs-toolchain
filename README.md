<h1 align="center">
<a href="https://undraw.co/"><img src="logo/landing_page.svg" alt="Docs Toolchain Logo"></a>
</h1>

[![Github workflow](https://github.com/wirecard/docs-toolchain/workflows/Main/badge.svg)](https://github.com/wirecard/docs-toolchain/actions)
[![Coverage Status](https://coveralls.io/repos/github/wirecard/docs-toolchain/badge.svg?branch=coveralls)](https://coveralls.io/github/wirecard/docs-toolchain?branch=coveralls)
[![Inline docs](http://inch-ci.org/github/wirecard/docs-toolchain.svg?branch=master)](http://inch-ci.org/github/wirecard/docs-toolchain)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

# docs-toolchain
Toolchain for TecDoc managed documentation repositories

<div align="center">

[![Built with Ruby](https://forthebadge.com/images/badges/made-with-ruby.svg)](https://forthebadge.com) [![Built with Science](https://forthebadge.com/images/badges/built-with-science.svg)](https://forthebadge.com) [![forthebadge](https://forthebadge.com/images/badges/built-with-love.svg)](https://forthebadge.com) [![Uses Badges](https://forthebadge.com/images/badges/uses-badges.svg)](https://forthebadge.com) [![Approved](https://forthebadge.com/images/badges/approved-by-george-costanza.svg)](https://forthebadge.com)

</div>


## Docs and Metrics
* [Source Code Documentation (rdoc)](https://wirecard.github.io/docs-toolchain/rdoc/)
* [SimpleCov Coverage](https://wirecard.github.io/docs-toolchain/coverage/)
* [RubyCritic](https://wirecard.github.io/docs-toolchain/rubycritic)

## Quickstart
### Dependencies
To run the toolchain locally, or run the unit tests, the following requirements must be met:
* Ruby 2.x
* installed dependencies (Gemfile)

In order to install dependencies, run the following at the root of the project:
```bash
bash stages/setup/setup_main.sh
```

### Build
Building the content can be done one stage after another:
```sh
rake docs:clean
rake docs:test
rake docs:pre
rake docs:build
rake docs:post
```

or by using the target `all`, which runs all of the stages mentioned above:
```sh
rake docs:all
```

Alternatively, use the Docker image at [wirecard/docs-dockerfile](https://github.com/wirecard/docs-dockerfile).

## Stages
The toolchain is designed to run through different stages, that have specific responsibilities:
1. **setup**: install required dependencies
2. **test**:
  * validate all configuration files
  * test the current commit with:
    * predefined tests by the toolchain (`lib/extensions.d/`)
      * ID Checker
      * `if` Checker
      * Link Checker
      * Pattern Checker
    * [*future*] custom tests (`${CONTENT_REPO}/extensions.d/`)
3. **pre**:
  * combine Javascript files to BLOB file
  * transpile (cross-browser compatibility and loading speed)
4. **build**:
  * invoke asciidoctor (with multipage converter)
  * [*future*] run custom build scripts `build.d/*.sh`
  * [*future*] diagram integration
  * Table of Content injector
  * CodeRay source code highlighter
5. **post**:
  * create Table of Content
  * create search index (Lunr)
  * [*future*] trigger translation
6. **deploy**:
  * [wirecard/s3-deploy](https://github.com/wirecard/s3-deploy)
  * [crazy-max/ghaction-github-pages](https://github.com/crazy-max/ghaction-github-pages)
  * required variables, see [Configuration/Secret/AWS](#Secret)
7. **notify**:
  * send Slack message stating the fail status and a description if the build failed, see [Configuration/Secret/Slack](#Secret)


## Development
### Rake targets
#### Toolchain
* `rake toolchain:lint` calls rubocop
* `rake toolchain:test` runs unit tests with `simplecov` and writes report to `coverage/index.html`
* `rake toolchain:quality` runs `rubycritic` and generates an overview in `/tmp/rubycritic/overview.html`
* `rake toolchain:rdoc` generates rdoc documentation in `/tmp/rdoc`
* `rake toolchain:inch:grade` or `rake toolchain:inch:suggest` runs `inch` on the code base

#### Content (Stages)
1. _No rake task:_ `bash setup/setup.sh`
2. `rake docs:test`
3. `rake docs:pre`
4. `rake docs:build`
5. `rake docs:post`
6. _No rake task:_ Deployed by Github Action
7. _No rake task:_ Separate Github Action

**Additional tasks**
* `rake docs:clean`: delete build directory and clean up
* `rake docs:all`: run the stages `clean test pre build post`
* `rake docs:list:<stage>`: list loaded extensions for a processing stage
* `rake docs:list:pre`
* `rake docs:list:post`


### Environment Variables
* `SKIP_COMBINE`: skips the Javascript combine and transpile operation.
* `SKIP_HTMLCHECK`: skips the HTML Check Post process.
* Skip entire stages
  * `SKIP_RAKE_TEST`: skips test stage (i.e. `rake docs:test`)
* `FAST` sets the following variables (which may be set individually):
  * `SKIP_COMBINE`, `SKIP_HTMLCHECK`, `SKIP_RAKE_TEST`
* `DEBUG` for debug builds
* `SKIP_COMBINE`
* additional debug output

