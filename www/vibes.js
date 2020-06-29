/*
* Licensed to the Apache Software Foundation (ASF) under one
* or more contributor license agreements.  See the NOTICE file
* distributed with this work for additional information
* regarding copyright ownership.  The ASF licenses this file
* to you under the Apache License, Version 2.0 (the
* "License"); you may not use this file except in compliance
* with the License.  You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
* KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations
* under the License.
*/
var vibes = {

    registerDevice: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "registerDevice", []);
    },
    unregisterDevice: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "unregisterDevice", []);
    },
    associatePerson: function (externalPersonId, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "associatePerson", [externalPersonId]);
    },
    registerPush: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "registerPush", []);
    },
    unregisterPush: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "unregisterPush", []);
    },
    getVibesDeviceInfo: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "getVibesDeviceInfo", []);
    },
    getPerson: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "getPerson", []);
    },
    onNotificationOpened: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "onNotificationOpened", []);
    },
    fetchInboxMessages: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "fetchInboxMessages", []);
    },
    expireInboxMessage: function (messageId, date, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "expireInboxMessage", [messageId, date]);
    },
    markInboxMessageAsRead: function(messageId, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "markInboxMessageAsRead", [messageId]);
    },
    fetchInboxMessage: function(messageId, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "fetchInboxMessage", [messageId]);
    },
    onInboxMessageOpen: function(inboxMessage, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VibesPlugin", "onInboxMessageOpen", [inboxMessage]);
    },
    
};

module.exports = vibes;
