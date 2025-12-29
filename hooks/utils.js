const fs = require('fs'),
    path = require('path'),
    xml2js = require('xml2js')

//Initial configs
const configs = {
    textToReplace: 'There was an error processing your request.',
    androidPath: "/platforms/android/app/src/main/assets/www/",
    androidMainPath: "/platforms/android/app/src/main/",
    androidAppPath: "/platforms/android/app/",
    configPathAndroid: "/platforms/android/app/src/main/res/xml/config.xml",
    configPathIos: "/platforms/ios/MijnSalland/config.xml",
    androidManifest: "AndroidManifest.xml",
    iosPath: "/platforms/ios/www/",
    iosMainPath: "/platforms/ios/",
    errorFile: '_error.html',
    indexFile: 'index.html',
    urlPath: 'MijnSalland',
    pluginId: 'cordova-os-build-changer'
};

function getConfigs() {
    return configs;
}

function readFile(filePath) {
    return fs.readFileSync(filePath, "utf-8");
}


function indexReplacer(indexPath, content) {

    content = content.replace('<script type="text/javascript" src="scripts/cordova.js', '<script>function handleOpenURL(url) {console.log(url);}</script><script type="text/javascript" src="scripts/cordova.js');
    console.log('Added openURLhandler JS function.')

    fs.writeFileSync(indexPath, content, "utf-8");
}


module.exports = {
    getConfigs,
    readFile,
    indexReplacer
}