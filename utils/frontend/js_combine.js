const fs = require('fs');
const cheerio = require('cheerio');
const minify = require("babel-minify");
const { CONTENT_PATH, log } = require('../js/modules/common');

const HEADER = true;
const FOOTER = false;

/**
 * Combine all .js files found in CONTENTDIR/js/header.d/ and CONTENTDIR/js/footer.d/
 * then combine them and include them in docinfo{,-footer}.html
 */

function combineJS(location) {
    if (location == HEADER) {
        htmlFile = 'docinfo.html';
        jsBlobFile = 'js-combined-header.js';
        contentScriptsDir = 'js/header.d/';
    }
    if (location == FOOTER) {
        htmlFile = 'docinfo-footer.html';
        jsBlobFile = 'js-combined-footer.js';
        contentScriptsDir = 'js/footer.d/';
    }
    log('Combining js files in ' + htmlFile);
    var html = null;
    try {
        html = fs.readFileSync(htmlFile);
    } catch (err) {
        log('Could not read ' + htmlFile, 'WARN');
        return true;
    }

    var jsBundle = [];
    var $ = cheerio.load(html, {
        xmlMode: true // to avoid wrapping html head tags
    });

    log('Combining js included in ' + htmlFile + ' to ' + jsBlobFile + ':');
    // for each included .js file remove the tag, add js content of included file to blob
    $('script[src]').each(function () {
        const scriptFilename = $(this).attr('src');
        if (scriptFilename == jsBlobFile) return false;
        const scriptContent = fs.readFileSync(scriptFilename);
        jsBundle.push(scriptContent);
        log(' ' + scriptFilename, 'DEBUG');
        $(this).remove();
    });

    // read included
    const dirCont = fs.readdirSync(path).filter((elm) => /.*\.js$/gi.test(elm));

    try {
        fs.writeFileSync(jsBlobFile, jsBundle.join("\n\n" + '// included from ' + scriptFilename + "\n"));
    } catch (err) {
        throw err;
    }
    try {
        if (header) {
            fs.writeFileSync(htmlFile, '<script src="' + jsBlobFile + '"></script>' + "\n" + $.html());
        }
        else {
            fs.writeFileSync(htmlFile, $.html() + "\n" + '<script src="' + jsBlobFile + '"></script>');
        }
    } catch (err) {
        throw err;
    }
    return true;
}

function minifyJSFiles(path) {
    log('Minifying js files');
    path = (path !== undefined) ? path : CONTENT_PATH + 'js/';
    if(fs.existsSync(path) !== true) {
        log('Folder ' + path + ' does not exist. Did not combine frontend js files.', 'WARN');
        return true;
    }
    const dirCont = fs.readdirSync(path);
    const jsFiles = dirCont.filter((elm) => /.*\.js$/gi.test(elm));
    for (var i in jsFiles) {
        const jsFile = jsFiles[i];
        var minifiedJS;
        process.stderr.write('minifying ' + jsFile + "\r");
        try {
            const js = fs.readFileSync(path + jsFile).toString();
            _minJS = minify(js);
            if (_minJS.code === undefined) {
                process.stderr.write('skipped ' + jsFile + " \n");
                console.log(_minJS);
                continue;
            }
            minifiedJS = _minJS.code;
        } catch (err) {
            throw err;
        }
        try {
            fs.writeFileSync(path + jsFile, minifiedJS);
        } catch (err) {
            throw err;
        }
        process.stderr.write('minified ' + jsFile + " \n");
    }
    return true;
}

return (
    combineJS(HEADER) && combineJS(FOOTER) && minifyJSFiles()
);
