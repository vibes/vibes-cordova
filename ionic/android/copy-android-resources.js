#!/usr/bin/env node

// Copy native resources
var rootdir = process.argv[2];
var exec = require('child_process').exec;

// Native resources to copy
var androidNativePath = 'native/android/';

// Android platform resource path
var androidResPath = 'platforms/android/app/src/main/res/';

function copyAndroidResources() {
  console.log("Copying android resourcces")
  exec('cp -Rf ' + androidNativePath + '* ' + androidResPath);
  process.stdout.write('Copied android native resources');
}


module.exports = function(ctx) {
  copyAndroidResources();
};