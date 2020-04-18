//  RNAudioRecorderPlayer.m
//  dooboolab
//
//  Created by dooboolab on 16/04/2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "RNAudioRecorderPlayer.h"
#import <React/RCTLog.h>
#import <React/RCTConvert.h>
#import <AVFoundation/AVFoundation.h>

NSString *const OutputPhone = @"Phone";
NSString *const OutputPhoneSpeaker = @"Phone Speaker";
NSString *const OutputBluetooth = @"Bluetooth";
NSString *const OutputHeadphones = @"Headphones";

NSString* GetDirectoryOfType_Sound(NSSearchPathDirectory dir) {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
  return [paths.firstObject stringByAppendingString:@"/"];
}

@implementation RNAudioRecorderPlayer {
  NSURL *audioFileURL;
  AVAudioRecorder *audioRecorder;
  AVAudioPlayer *audioPlayer;
  NSTimer *recordTimer;
  NSTimer *playTimer;
}
double subscriptionDuration = 0.1;

// Audio -- IF audio is finished
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  NSLog(@"audioPlayerDidFinishPlaying");
  NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
  NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.duration * 1000];

  // Send last event then finish it.
  // NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
  NSDictionary *status = @{
                         @"duration" : [duration stringValue],
                         @"current_position" : [duration stringValue],
                         };
  [self sendEventWithName:@"rn-playback" body: status];


  if (playTimer != nil) {
    [playTimer invalidate];
    playTimer = nil;
  }
}


- (void)updateProgress:(NSTimer*) timer
{
  NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
  NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

  NSLog(@"updateProgress: %@", duration);

  if ([duration intValue] == 0) {
    [playTimer invalidate];
    [audioPlayer stop];
    return;
  }

  // NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
  NSDictionary *status = @{
                         @"duration" : [duration stringValue],
                         @"current_position" : [currentTime stringValue],
                         };

  [self sendEventWithName:@"rn-playback" body:status];
}






- (void)startPlayerTimer
{
  dispatch_async(dispatch_get_main_queue(), ^{
      self->playTimer = [NSTimer scheduledTimerWithTimeInterval: subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
  });
}


RCT_EXPORT_METHOD(setVolume:(double) volume
                  resolve:(RCTPromiseResolveBlock) resolve
                  reject:(RCTPromiseRejectBlock) reject) {
    [audioPlayer setVolume: volume];
    resolve(@"setVolume");
}

RCT_EXPORT_METHOD(startPlayer:(NSString*)path
                  options:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
                  {
    NSError *error;

    NSString *output = [RCTConvert NSString:options[@"output"]];


    if ([[path substringToIndex:4] isEqualToString:@"http"]) {
        audioFileURL = [NSURL URLWithString:path];

        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
        dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // NSData *data = [NSData dataWithContentsOfURL:audioFileURL];

                audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
                audioPlayer.delegate = self;


            // Able to play in silent mode
            [[AVAudioSession sharedInstance]
                setCategory: AVAudioSessionCategoryPlayback
                error: &error];
            // Able to play in background
            [[AVAudioSession sharedInstance] setActive: YES error: nil];
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

            NSString *filePath = audioFileURL.absoluteString;

            NSNumber *dur =  [NSNumber numberWithDouble:audioPlayer.duration * 1000];
            resolve(dur);
        }];

        [downloadTask resume];
    } else {
        if ([path isEqualToString:@"DEFAULT"]) {
          audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_Sound(NSCachesDirectory) stringByAppendingString:@"sound.m4a"]];
        } else {
            if ([path rangeOfString:@"file://"].location == NSNotFound) {
                audioFileURL = [NSURL fileURLWithPath: [GetDirectoryOfType_Sound(NSCachesDirectory) stringByAppendingString:path]];
            } else {
                audioFileURL = [NSURL URLWithString:path];
            }
        }

        NSLog(@"Error %@",error);

            RCTLogInfo(@"audio player alloc");
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
            audioPlayer.delegate = self;


        // Able to play in silent mode
        [[AVAudioSession sharedInstance]
            setCategory: AVAudioSessionCategoryPlayback
            error: nil];

        NSLog(@"Error %@",error);

        NSString *filePath = audioFileURL.absoluteString;
         NSNumber *dur =  [NSNumber numberWithDouble:audioPlayer.duration * 1000];
                    resolve(dur);
    }
}

RCT_EXPORT_METHOD(play:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
                  {

    NSString *output = [RCTConvert NSString:options[@"output"]];



            [self setAudioOutput:output];

            [audioPlayer play];
            [self startPlayerTimer];
            NSString *filePath = audioFileURL.absoluteString;
            resolve(filePath);

}

RCT_EXPORT_METHOD(resumePlayer: (RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    if (!audioFileURL) {
        reject(@"audioRecorder resume", @"no audioFileURL", nil);
        return;
    }

    if (!audioPlayer) {
        reject(@"audioRecorder resume", @"no audioPlayer", nil);
        return;
    }

    [[AVAudioSession sharedInstance]
        setCategory: AVAudioSessionCategoryPlayback
        error: nil];
    [audioPlayer play];
    [self startPlayerTimer];
    NSString *filePath = audioFileURL.absoluteString;
    resolve(filePath);
}

RCT_EXPORT_METHOD(seekToPlayer: (nonnull NSNumber*) time
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    if (audioPlayer) {
        audioPlayer.currentTime = [time doubleValue];
    } else {
        reject(@"audioPlayer seekTo", @"audioPlayer is not set", nil);
    }
}

- (void)setAudioOutput:(NSString *)output {
    NSLog(@"Output %@",output);
  if([output isEqualToString:OutputPhoneSpeaker]){
    printf("OutputPhoneSpeaker");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];

  } else if ([output isEqualToString:OutputPhone]){
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    printf("OutputPhone");
  } else {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
  }
}

RCT_EXPORT_METHOD(pausePlayer: (RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    RCTLogInfo(@"pause");
    if (audioPlayer && [audioPlayer isPlaying]) {
        [audioPlayer pause];
        if (playTimer != nil) {
            [playTimer invalidate];
            playTimer = nil;
        }
        resolve(@"pause play");
    } else {
        reject(@"audioPlayer pause", @"audioPlayer is not playing", nil);
    }
}


RCT_EXPORT_METHOD(stopPlayer:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {

    NSLog(@"STOP!!!!-");

    if (audioPlayer) {
        if (playTimer != nil) {
            [playTimer invalidate];
            playTimer = nil;
        }
        [audioPlayer stop];
        resolve(@"stop play");
    } else {
        reject(@"audioPlayer stop", @"audioPlayer is not set", nil);
    }
}


RCT_EXPORT_METHOD(getOutputs:(RCTResponseSenderBlock)callback)
{
  //Reset audio output route and session catetory when get the list
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];

  NSMutableArray *array;
  BOOL isHeadsetOn = false;
  BOOL isBluetoothConnected = false;

  AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
  for (AVAudioSessionPortDescription* desc in [route outputs]) {
    if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
      isHeadsetOn = true;
      continue;
    }

    if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
        [[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE] ||
        [[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP]) {
      isBluetoothConnected = true;
    }
  }
  if (isHeadsetOn) {
    array = [NSMutableArray arrayWithArray: @[OutputHeadphones]];
  } else if (isBluetoothConnected) {
    array = [NSMutableArray arrayWithArray: @[OutputPhone, OutputPhoneSpeaker, OutputBluetooth]];
  } else {
    array = [NSMutableArray arrayWithArray: @[OutputPhone, OutputPhoneSpeaker]];
  }

  callback(@[array]);
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"rn-recordback", @"rn-playback"];
}

RCT_EXPORT_METHOD(setSubscriptionDuration:(double)duration
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  subscriptionDuration = duration;
  resolve(@"set subscription duration.");
}


// Recorder






- (void)updateRecorderProgress:(NSTimer*) timer
{
  NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];
  // NSString* status = [NSString stringWithFormat:@"{\"current_position\": \"%@\"}", [currentTime stringValue]];
  NSDictionary *status = @{
                         @"current_position" : [currentTime stringValue],
                         };
  [self sendEventWithName:@"rn-recordback" body:status];
}


- (void)startRecorderTimer
{
  dispatch_async(dispatch_get_main_queue(), ^{
      self->recordTimer = [NSTimer scheduledTimerWithTimeInterval: subscriptionDuration
                                           target:self
                                           selector:@selector(updateRecorderProgress:)
                                           userInfo:nil
                                           repeats:YES];
  });
}


RCT_EXPORT_METHOD(startRecorder:(NSString*)path
                  audioSets: (NSDictionary*)audioSets
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {

  NSString *encoding = [RCTConvert NSString:audioSets[@"AVFormatIDKeyIOS"]];
  NSNumber *sampleRate = [RCTConvert NSNumber:audioSets[@"AVSampleRateKeyIOS"]];
  NSNumber *numberOfChannel = [RCTConvert NSNumber:audioSets[@"AVNumberOfChannelsKeyIOS"]];
  NSNumber *avFormat;
  NSNumber *audioQuality = [RCTConvert NSNumber:audioSets[@"AVEncoderAudioQualityKeyIOS"]];

  if ([path isEqualToString:@"DEFAULT"]) {
    audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_Sound(NSCachesDirectory) stringByAppendingString:@"sound.m4a"]];
  } else {
    audioFileURL = [NSURL fileURLWithPath: [GetDirectoryOfType_Sound(NSCachesDirectory) stringByAppendingString:path]];
  }

  if (!sampleRate) {
      sampleRate = [NSNumber numberWithFloat:44100];
  }
  if (!encoding) {
    avFormat = [NSNumber numberWithInt:kAudioFormatAppleLossless];
  } else {
    if ([encoding  isEqual: @"lpcm"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatLinearPCM];
    } else if ([encoding  isEqual: @"ima4"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatAppleIMA4];
    } else if ([encoding  isEqual: @"aac"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatMPEG4AAC];
    } else if ([encoding  isEqual: @"MAC3"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatMACE3];
    } else if ([encoding  isEqual: @"MAC6"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatMACE6];
    } else if ([encoding  isEqual: @"ulaw"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatULaw];
    } else if ([encoding  isEqual: @"alaw"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatALaw];
    } else if ([encoding  isEqual: @"mp1"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatMPEGLayer1];
    } else if ([encoding  isEqual: @"mp2"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatMPEGLayer2];
    } else if ([encoding  isEqual: @"alac"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatAppleLossless];
    } else if ([encoding  isEqual: @"amr"]) {
      avFormat =[NSNumber numberWithInt:kAudioFormatAMR];
    } else if ([encoding  isEqual: @"flac"]) {
        if (@available(iOS 11, *)) avFormat =[NSNumber numberWithInt:kAudioFormatFLAC];
    } else if ([encoding  isEqual: @"opus"]) {
        if (@available(iOS 11, *)) avFormat =[NSNumber numberWithInt:kAudioFormatOpus];
    }
  }
  if (!numberOfChannel) {
    numberOfChannel = [NSNumber numberWithInt:2];
  }
  if (!audioQuality) {
    audioQuality = [NSNumber numberWithInt:AVAudioQualityMedium];
  }

  NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                 sampleRate, AVSampleRateKey,
                                 avFormat, AVFormatIDKey,
                                 numberOfChannel, AVNumberOfChannelsKey,
                                 audioQuality, AVEncoderAudioQualityKey,
                                 nil];

  // Setup audio session
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

  // set volume default to speaker
  UInt32 doChangeDefaultRoute = 1;
  AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);

  audioRecorder = [[AVAudioRecorder alloc]
                        initWithURL:audioFileURL
                        settings:audioSettings
                        error:nil];

  [audioRecorder setDelegate:self];
  [audioRecorder record];
  [self startRecorderTimer];

  NSString *filePath = self->audioFileURL.absoluteString;
  resolve(filePath);
}

RCT_EXPORT_METHOD(stopRecorder:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    if (audioRecorder) {
        [audioRecorder stop];
        if (recordTimer != nil) {
            [recordTimer invalidate];
            recordTimer = nil;
        }

        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];

        NSString *filePath = audioFileURL.absoluteString;
        resolve(filePath);
    } else {
        reject(@"audioRecorder record", @"audioRecorder is not set", nil);
    }
}


@end
