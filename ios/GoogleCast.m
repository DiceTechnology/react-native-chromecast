#import "GoogleCast.h"
#import "GoogleCastManager.h"
#import <React/RCTLog.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>


static NSString *const DEVICE_AVAILABLE = @"GoogleCast:DeviceAvailable";
static NSString *const DEVICES_UPDATED = @"GoogleCast:DevicesUpdated";

static NSString *const DEVICE_CONNECTED = @"GoogleCast:DeviceConnected";
static NSString *const DEVICE_DISCONNECTED = @"GoogleCast:DeviceDisconnected";
static NSString *const MEDIA_LOADED = @"GoogleCast:MediaLoaded";


@implementation GoogleCast
@synthesize bridge = _bridge;
BOOL createdCastContext = NO;
RCT_EXPORT_MODULE();

- (NSDictionary *)constantsToExport
{
  return @{

           @"DEVICE_AVAILABLE": DEVICE_AVAILABLE,
           @"DEVICE_CONNECTED": DEVICE_CONNECTED,
           @"DEVICE_DISCONNECTED": DEVICE_DISCONNECTED,
           @"MEDIA_LOADED": MEDIA_LOADED,
           @"DEVICES_UPDATED": DEVICES_UPDATED
           };
}


RCT_EXPORT_METHOD(startScan)
{
  RCTLogInfo(@"start scan chromecast!");

  dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"running");
      NSLog(@"%@", self.currentDevices);
      if(!createdCastContext) {
          self.currentDevices = [[NSMutableDictionary alloc] init];
          self.deviceList = [[NSMutableArray alloc] init];
        GCKCastOptions *options = [[GCKCastOptions alloc] initWithReceiverApplicationID:kGCKMediaDefaultReceiverApplicationID];
        [GCKCastContext setSharedInstanceWithOptions:options];
        [GCKCastContext sharedInstance].useDefaultExpandedMediaControls = YES;
          createdCastContext = YES;
      }
    self.discoveryManager = [[GCKCastContext sharedInstance] discoveryManager];
    [_discoveryManager addListener:self];
    [_discoveryManager startDiscovery];
    [_discoveryManager setPassiveScan:NO];
      if(self.discoveryManager.deviceCount > 0 && self.deviceList) {
          [self emitMessageToRN:DEVICE_AVAILABLE
          :@{@"device_available": @YES}];
          [self emitMessageToRN:DEVICES_UPDATED :@{@"devices": self.deviceList}];

      }
  });
}

RCT_EXPORT_METHOD(stopScan)
{
  RCTLogInfo(@"stop chromecast!");
  dispatch_async(dispatch_get_main_queue(), ^{
    [_discoveryManager removeListener:self];
  });
}

RCT_REMAP_METHOD(isConnected,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)

{
  BOOL isConnected = self.deviceManager.connectionState == GCKConnectionStateConnected;
  RCTLogInfo(@"is connected? %d", isConnected);
  resolve(@(isConnected));

}

RCT_EXPORT_METHOD(connectToDevice:(NSString *)deviceId)
{
  RCTLogInfo(@"connecting to device %@", deviceId);
  GCKDevice *selectedDevice = self.currentDevices[deviceId];

  dispatch_async(dispatch_get_main_queue(), ^{
    self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:selectedDevice
                                                clientPackageName:[NSBundle mainBundle].bundleIdentifier ignoreAppStateNotifications:YES];
    self.deviceManager.delegate = self;
    [_deviceManager connect];
  });
}

RCT_EXPORT_METHOD(disconnect)
{
  if(self.deviceManager == nil) return;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.deviceManager disconnectWithLeave:YES];
  });
}

RCT_EXPORT_METHOD(castMedia
                  :(NSString *)mediaUrl
                  :(NSString *) title
                  :(NSString *)imageUrl
                  :(double)seconds)
{
  RCTLogInfo(@"casting media");
  seconds = !seconds ? 0 : seconds;

  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];

  [metadata setString:title forKey:kGCKMetadataKeyTitle];

  [metadata addImage:[[GCKImage alloc]
                      initWithURL:[[NSURL alloc] initWithString: imageUrl]
                      width:480
                      height:360]];

  GCKMediaInformation *mediaInformation =
  [[GCKMediaInformation alloc] initWithContentID: mediaUrl
                                      streamType: GCKMediaStreamTypeNone
                                     contentType: @"video/mp4"
                                        metadata: metadata
                                  streamDuration: 0
                                      customData: nil];

  // Cast the video.
  [self.mediaControlChannel loadMedia:mediaInformation autoplay:YES playPosition: seconds];
}

RCT_EXPORT_METHOD(togglePauseCast)
{
  BOOL isPlaying = self.mediaControlChannel.mediaStatus.playerState == GCKMediaPlayerStatePlaying;
  isPlaying ? [self.mediaControlChannel pause] : [self.mediaControlChannel play];
}

RCT_EXPORT_METHOD(seekCast:(double) seconds){
  [self.mediaControlChannel seekToTimeInterval: seconds];
}

RCT_REMAP_METHOD(getStreamPosition,
                 resolved:(RCTPromiseResolveBlock)resolve
                 rejected:(RCTPromiseRejectBlock)reject)
{
  double time = [self.mediaControlChannel approximateStreamPosition];
  resolve(@(time));
}

- (NSArray<NSString *> *)supportedEvents {
    return @[DEVICES_UPDATED, DEVICE_AVAILABLE, DEVICE_CONNECTED, DEVICE_DISCONNECTED, MEDIA_LOADED];
}


#pragma mark - GCKDeviceScannerListener

- (void)didInsertDevice:(GCKDevice *)device atIndex:(NSUInteger)index {
  NSLog(@"device found!! %@", device.friendlyName);
  [self emitMessageToRN:DEVICE_AVAILABLE
                       :@{@"device_available": @YES}];
  [self addDevice: device];
}

- (void)didRemoveDeviceAtIndex:(NSUInteger)index {
    NSLog(@"remove");
  [self removeDevice: index];
  if([self.currentDevices count] == 0) {
    [self emitMessageToRN:DEVICE_AVAILABLE
                         :@{@"device_available": @NO}];
  }
}

- (void) didUpdateDeviceList {
    NSLog(@"update");
}


#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
  // Launch application after getting connected.
  [_deviceManager launchApplication: kGCKMediaDefaultReceiverApplicationID];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(NSError *)error {
    [self emitMessageToRN:DEVICE_DISCONNECTED
                         :nil];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication
                     :(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication {

  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  [_deviceManager addChannel:self.mediaControlChannel];

  //send message to react native
  [self emitMessageToRN:DEVICE_CONNECTED
                       :nil];
}

- (void) deviceManager:(GCKDeviceManager *)deviceManager didDisconnectFromApplicationWithError:(NSError *__nullable)error {
    [self emitMessageToRN:DEVICE_DISCONNECTED
                         :nil];
}

- (void) mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel didCompleteLoadWithSessionID:(NSInteger)sessionID {
  [self emitMessageToRN:MEDIA_LOADED
                       :nil];
}


#pragma mark - Private methods
- (void) addDevice: (GCKDevice *)device {
    NSMutableDictionary *singleDevice = [[NSMutableDictionary alloc] init];
    singleDevice[@"id"] = device.deviceID;
    singleDevice[@"name"] = device.friendlyName;
    singleDevice[@"device"] = device;
    self.currentDevices[device.deviceID] = device;
    [self.deviceList addObject:singleDevice];
    [self emitMessageToRN:DEVICES_UPDATED :@{@"devices": self.deviceList}];

}

- (void) removeDevice: (NSUInteger)index {
//    int num = (int)index;
    NSArray *keys = [self.currentDevices allKeys];
    id key = [keys objectAtIndex:index];

    [self.currentDevices removeObjectForKey: key];
    [self.deviceList removeObjectAtIndex:index];
    [self emitMessageToRN:DEVICES_UPDATED :@{@"devices": self.deviceList}];
}

- (void) emitMessageToRN: (NSString *)eventName
                        :(NSDictionary *)params{
  [self sendEventWithName: eventName body: params];
}



@end
