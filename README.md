# docs-toolchain
Toolchain for TecDoc managed documentation repositories


## Stages
The toolchain is designed to run through different stages, that have specific responsibilities:
1. **setup**: install required dependencies and setup the template/build folder
2. **test**:
    * create info files (like git information, e.g. branch, commit author, last edited by, etc.)
    * validate all configuration files
    * test the current commit with:
        * predefined tests
        * custom test scripts (in `tests.d/*.sh`)
        * abort the build if necessary
    * `/tmp/errors.json` is the central point of warnings and errors, each testing stage will add warnings/errors to this file via the script `add-error.py`.
    * *optional*: send slack message
3. **build**:
    * invoke asciidoctor (with multipage converter)
    * create Table of Content
    * create search index (Lunr)
    * `DEBUG` build: pass through to asciidoctor as `:debug:` to enable the debug build which will (local testing only):
        * NOT minify and combine Javascript files
        * NOT minify CSS
    * frontend functionality:
        * `header.js.d/`: scripts that need to be loaded at the beginning, will be combined to `header.js` and minified
        * `footer.js.d/`: scripts that need to be loaded at the end, will be combined to `footer.js` and minified
    * run custom build scripts `build.d/*.sh`
4. **deploy**:
    * [wirecard/s3-deploy](https://github.com/wirecard/s3-deploy)
    * required variables, see [Configuration/Secret/AWS](#Secret)

5. **post-processing**:
    * send Slack message if everything passed, see [Configuration/Secret/Slack](#Secret)

## Configuration
There are some variables that need to be secret, while others can be public.
Configuration files are public.

### Secret
* **AWS**
    * `AWS_ACCESS_KEY_ID`
    * `AWS_SECRET_ACCESS_KEY`
    * `AWS_REGION`
* **Slack**
    * `SLACK_TOKEN` (Optional)

### Public
#### Variables
* **AWS**
    * `AWS_S3_BUCKET`

#### Files
Configuration files:
* `config/settings.json`
* `config/invalid-patterns.json`
* `config/error-types.json`: lists all warning/error types with a unique string ID, a unique error code (grouped like HTTP codes), and a format string like error message.
* `static/privacy-policy.(txt|adoc)`


## Utilities
The **test** and **build** stages produce `/tmp/errors.json`, a central file containing all warnings and errors that occured during the **test** or **build** stages.
Warnings and errors are defined in `error-types.json` and further ignored or interpreted as errors according to `settings.json`.
`slack-notifiy.py` sends these warnings and/or errors (if there are any) to a Slack channel, defined in the secret variable `SLACK_TOKEN`.
Otherwise 