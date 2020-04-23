const fs = require('fs'),
	path = require('path');

var self = (module.exports = {
	searchAndReplace: function(filePath, arrayStringToSearch, arrayStringToReplace) {
		if (arrayStringToSearch.length != arrayStringToReplace.length) {
			throw new Error('search/replace array lengths do not match');
		}

		let data = fs.readFileSync(filePath, 'utf8');

		if (self.isEmptyString(data)) {
			throw new Error(`file at ${filePath} is empty`);
		}

		for (var i = 0; i < arrayStringToSearch.length; i++) {
			data = data.replace(arrayStringToSearch[i], arrayStringToReplace[i]);
		}

		fs.writeFileSync(filePath, data, 'utf-8');
	},

	cordovaAppConfigForContext: function(context) {
		const cordovaCommon = context.requireCordovaModule('cordova-common');
		return new cordovaCommon.ConfigParser('config.xml');
	},
    
    deleteFolderRecursive: function(filePath) {
        if (fs.existsSync(filePath)) {
          fs.readdirSync(filePath).forEach((file, index) => {
            const curPath = path.join(filePath, file);
            if (fs.lstatSync(curPath).isDirectory()) { // recurse
              deleteFolderRecursive(curPath);
            } else { // delete file
              fs.unlinkSync(curPath);
            }
          });
          fs.rmdirSync(filePath);
        }
    },

	cordovaPackageNameForPlatform: function(appConfig, platform) {
		// check for the existence of platform-specific id, if it's not there fallback to basic id
		var packageName;

		if (platform == 'ios') {
			packageName = appConfig.ios_CFBundleIdentifier();
		}

		if (platform == 'android') {
			packageName = appConfig.android_packageName();
		}

		if (self.isEmptyString(packageName)) {
			packageName = appConfig.packageName();
		}

		return packageName;
	},

	isEmptyString: function(str) {
		return !str || 0 === str.length;
	},

	convertToBoolean: function(str) {
		if (str === undefined) {
			return false;
		}

		let canditateStr = str.toLowerCase();
		return canditateStr == 'true' ? true : false;
	},

	/**
     * Synchronous stat(2) - Get file status.
     * @param srcPath A path to a filde/folder that will be copied.
	 * @param destPath a path to destination that will copy the files/subfolders recursively. - its important be aware that this method will not create any folder on destPath that do not exist.
     */
	copyRecursiveSync: function(srcPath, destPath) {
		let exists = fs.existsSync(srcPath);
		let stats = exists && fs.statSync(srcPath);
		let isDirectory = exists && stats.isDirectory();
		if (exists && isDirectory) {
			fs.mkdirSync(destPath);
			// in a sync way we just check for each file in the folder and if its a directory call the same method recursive to copy its content as well
			fs.readdirSync(srcPath).forEach(function(childItemName) {
				self.copyRecursiveSync(path.join(srcPath, childItemName), path.join(destPath, childItemName));
			});
		} else {
			fs.linkSync(srcPath, destPath);
		}
	}
});