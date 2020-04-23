const fs = require('fs');
const xcode = require('xcode');
const vibesUtils = require('./vibes-utils');

module.exports = function(context) {
    console.log('Starting hook to add iOS RichPush notification extension to project');

    const cordovaCommon = require('cordova-common');
    const appConfig = new cordovaCommon.ConfigParser('config.xml');
    const appName = appConfig.name();
    const packageName = vibesUtils.cordovaPackageNameForPlatform(appConfig, 'ios');
    const iosPath = 'platforms/ios/';
    const projPath = `${iosPath}${appName}.xcodeproj/project.pbxproj`;
    const extName = 'RichPush';
    const extFiles = [
        'NotificationService.swift',
        'RichPushNotificationParsing.swift',
        'vibes_custom.wav',
        `${extName}-Info.plist`,
    ];
    // The directory where the source extension files are stored
    const sourceDir = `extensions/ios/${extName}/`;

    // Wait a few seconds before parsing the project to let some other
    // asynchronous project file changes complete. Maybe there is a way to get
    // a promise?
    console.log('Waiting a few seconds for other project file changes to finish');
    vibesUtils.deleteFolderRecursive('platforms/ios/RichPush');
    setTimeout(function () {
        console.log(`Adding   notification extension to ${appName}`);
        let proj = xcode.project(projPath);
        proj.parse(function (err) {
            if (err) {
                console.log(`Error parsing iOS project: ${err}`);
            }
            // Copy in the extension files
            console.log('Copying in the extension files to the iOS project');
            fs.mkdirSync(`${iosPath}${extName}`);
            extFiles.forEach(function (extFile) {
                let targetFile = `${iosPath}${extName}/${extFile}`;
                fs.createReadStream(`${sourceDir}${extFile}`)
                    .pipe(fs.createWriteStream(targetFile));
            });
            // Create new PBXGroup for the extension
            console.log('Creating new PBXGroup for the extension');
            let extGroup = proj.addPbxGroup(extFiles, extName, extName);
            // Add the new PBXGroup to the CustomTemplate group. This makes the
            // files appear in the file explorer in Xcode.
            console.log('Adding new PBXGroup to CustomTemplate PBXGroup');
            let groups = proj.hash.project.objects['PBXGroup'];
            Object.keys(groups).forEach(function (key) {
                if (groups[key].name === 'CustomTemplate') {
                    proj.addToPbxGroup(extGroup.uuid, key);
                }
            });
            // Add a target for the extension
            console.log('Adding the new target');
            let target = proj.addTarget(extName, 'app_extension');
            // Add build phases to the new target
            console.log('Adding build phases to the new target');
            proj.addBuildPhase([ 'NotificationService.swift', 'RichPushNotificationParsing.swift'], 'PBXSourcesBuildPhase', 'Sources', target.uuid);
            proj.addBuildPhase(['vibes_custom.wav'], 'PBXResourcesBuildPhase', 'Resources', target.uuid);
            proj.addBuildPhase([], 'PBXFrameworksBuildPhase', 'Frameworks', target.uuid);
            console.log('Write the changes to the iOS project file');
            // Iterate through the entire XCBuildConfig for config of the new target PRODUCT_NAME and modify it
            var config = proj.hash.project.objects['XCBuildConfiguration'];
            for (var ref in config) {
                if (
                    config[ref].buildSettings !== undefined &&
                    config[ref].buildSettings.PRODUCT_NAME !== undefined &&
                    (config[ref].buildSettings.PRODUCT_NAME.includes(extName) || config[ref].buildSettings.PRODUCT_NAME == extName)
                ) {
                    console.log(`Entered the setting: ${config[ref].buildSettings.PRODUCT_NAME} of ${ref}`);

                    var INHERITED = '"$(inherited)"';
                    if (
                        !config[ref].buildSettings['FRAMEWORK_SEARCH_PATHS'] ||
                        config[ref].buildSettings['FRAMEWORK_SEARCH_PATHS'] === INHERITED
                    ) {
                        proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings['FRAMEWORK_SEARCH_PATHS'] = [
                            INHERITED
                        ];
                    }

                    proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings['IPHONEOS_DEPLOYMENT_TARGET'] =
                        '10.0';

                    var currentBundleID =
                        proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings['PRODUCT_BUNDLE_IDENTIFIER'];
                    if (
                        vibesUtils.isEmptyString(currentBundleID) ||
                        !currentBundleID.includes(`${packageName}.${extName}`)
                    ) {
                        console.log('Setting PRODUCT_BUNDLE_IDENTIFIER to ', `${packageName}.${extName}`);
                        proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings[
                            'PRODUCT_BUNDLE_IDENTIFIER'
                        ] = `${packageName}.${extName}`;
                    }
                    
                    // ensure code signing identity is pointed correctly
                    proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings[
                        'CODE_SIGN_STYLE'
                    ] = `"Manual"`;
                    proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings[
                        'DEVELOPMENT_TEAM'
                    ] = `"XXXXX"`;
                    proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings[
                        'CODE_SIGN_IDENTITY'
                    ] = `"iPhone Distribution"`;
                    proj.hash.project.objects['XCBuildConfiguration'][ref].buildSettings['PRODUCT_NAME'] = `${extName}`;
                }
            }
            fs.writeFileSync(projPath, proj.writeSync());
            console.log(`Added ${extName} notification extension to project`);
        });
    }, 10000);
};