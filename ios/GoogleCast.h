#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <GoogleCast/GoogleCast.h>

@interface GoogleCast : RCTEventEmitter <RCTBridgeModule, GCKDiscoveryManagerListener, GCKDeviceManagerDelegate,GCKMediaControlChannelDelegate, GCKMediaControlChannelDelegate>

@property GCKMediaControlChannel *mediaControlChannel;
@property(nonatomic, strong) GCKApplicationMetadata *applicationMetadata;
@property(nonatomic, strong) GCKDevice *selectedDevice;
@property(nonatomic, strong) GCKDeviceScanner* deviceScanner;
@property(nonatomic, strong) GCKDiscoveryManager* discoveryManager;
@property(nonatomic, strong) GCKDeviceManager* deviceManager;
@property(nonatomic, strong) GCKMediaInformation* mediaInformation;
@property(nonatomic, strong) NSMutableDictionary *currentDevices;
@property(nonatomic, strong) NSMutableArray *deviceList;

@end
