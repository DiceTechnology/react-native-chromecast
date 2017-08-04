import { NativeModules, requireNativeComponent } from 'react-native';

const { GoogleCast } = NativeModules;

console.log(GoogleCast);

export default {
  startScan: function () {
	GoogleCast.startScan();
  },
  stopScan: function () {
	GoogleCast.stopScan();
  },
  isConnected: function () {
	return GoogleCast.isConnected();
  },
  getDevices: function () {
	return GoogleCast.getDevices();
  },
  connectToDevice: function (deviceId: string) {
	GoogleCast.connectToDevice(deviceId);
  },
  disconnect: function () {
	GoogleCast.disconnect();
  },
  castMedia: function (mediaUrl: string, title: string, imageUrl: string, seconds: number = 0) {
	GoogleCast.castMedia(mediaUrl, title, imageUrl, seconds);
  },
  seekCast: function (seconds: number) {
	GoogleCast.seekCast(seconds);
  },
  togglePauseCast: function () {
	GoogleCast.togglePauseCast();
  },
  getStreamPosition: function () {
	return GoogleCast.getStreamPosition();
  },
  DEVICE_AVAILABLE: GoogleCast.DEVICE_AVAILABLE,
  DEVICES_UPDATED: GoogleCast.DEVICES_UPDATED,
  DEVICE_CONNECTED: GoogleCast.DEVICE_CONNECTED,
  DEVICE_DISCONNECTED: GoogleCast.DEVICE_DISCONNECTED,
  MEDIA_LOADED: GoogleCast.MEDIA_LOADED,
};

export const button =   requireNativeComponent('GoogleCast', null);
