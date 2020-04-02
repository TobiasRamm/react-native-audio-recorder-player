import { DeviceEventEmitter, NativeEventEmitter, NativeModules, Platform } from 'react-native';
const { RNAudioRecorderPlayer } = NativeModules;
export let AudioSourceAndroidType;
(function(AudioSourceAndroidType) {
  AudioSourceAndroidType[AudioSourceAndroidType.DEFAULT = 0] = 'DEFAULT';
  AudioSourceAndroidType[AudioSourceAndroidType.MIC = 1] = 'MIC';
  AudioSourceAndroidType[AudioSourceAndroidType.VOICE_UPLINK = 2] = 'VOICE_UPLINK';
  AudioSourceAndroidType[AudioSourceAndroidType.VOICE_DOWNLINK = 3] = 'VOICE_DOWNLINK';
  AudioSourceAndroidType[AudioSourceAndroidType.VOICE_CALL = 4] = 'VOICE_CALL';
  AudioSourceAndroidType[AudioSourceAndroidType.CAMCORDER = 5] = 'CAMCORDER';
  AudioSourceAndroidType[AudioSourceAndroidType.VOICE_RECOGNITION = 6] = 'VOICE_RECOGNITION';
  AudioSourceAndroidType[AudioSourceAndroidType.VOICE_COMMUNICATION = 7] = 'VOICE_COMMUNICATION';
  AudioSourceAndroidType[AudioSourceAndroidType.REMOTE_SUBMIX = 8] = 'REMOTE_SUBMIX';
  AudioSourceAndroidType[AudioSourceAndroidType.UNPROCESSED = 9] = 'UNPROCESSED';
  AudioSourceAndroidType[AudioSourceAndroidType.RADIO_TUNER = 1998] = 'RADIO_TUNER';
  AudioSourceAndroidType[AudioSourceAndroidType.HOTWORD = 1999] = 'HOTWORD';
})(AudioSourceAndroidType || (AudioSourceAndroidType = {}));
export let OutputFormatAndroidType;
(function(OutputFormatAndroidType) {
  OutputFormatAndroidType[OutputFormatAndroidType.DEFAULT = 0] = 'DEFAULT';
  OutputFormatAndroidType[OutputFormatAndroidType.THREE_GPP = 1] = 'THREE_GPP';
  OutputFormatAndroidType[OutputFormatAndroidType.MPEG_4 = 2] = 'MPEG_4';
  OutputFormatAndroidType[OutputFormatAndroidType.AMR_NB = 3] = 'AMR_NB';
  OutputFormatAndroidType[OutputFormatAndroidType.AMR_WB = 4] = 'AMR_WB';
  OutputFormatAndroidType[OutputFormatAndroidType.AAC_ADIF = 5] = 'AAC_ADIF';
  OutputFormatAndroidType[OutputFormatAndroidType.AAC_ADTS = 6] = 'AAC_ADTS';
  OutputFormatAndroidType[OutputFormatAndroidType.OUTPUT_FORMAT_RTP_AVP = 7] = 'OUTPUT_FORMAT_RTP_AVP';
  OutputFormatAndroidType[OutputFormatAndroidType.MPEG_2_TS = 8] = 'MPEG_2_TS';
  OutputFormatAndroidType[OutputFormatAndroidType.WEBM = 9] = 'WEBM';
})(OutputFormatAndroidType || (OutputFormatAndroidType = {}));
export let AudioEncoderAndroidType;
(function(AudioEncoderAndroidType) {
  AudioEncoderAndroidType[AudioEncoderAndroidType.DEFAULT = 0] = 'DEFAULT';
  AudioEncoderAndroidType[AudioEncoderAndroidType.AMR_NB = 1] = 'AMR_NB';
  AudioEncoderAndroidType[AudioEncoderAndroidType.AMR_WB = 2] = 'AMR_WB';
  AudioEncoderAndroidType[AudioEncoderAndroidType.AAC = 3] = 'AAC';
  AudioEncoderAndroidType[AudioEncoderAndroidType.HE_AAC = 4] = 'HE_AAC';
  AudioEncoderAndroidType[AudioEncoderAndroidType.AAC_ELD = 5] = 'AAC_ELD';
  AudioEncoderAndroidType[AudioEncoderAndroidType.VORBIS = 6] = 'VORBIS';
})(AudioEncoderAndroidType || (AudioEncoderAndroidType = {}));
export let AVEncodingOption;
(function(AVEncodingOption) {
  AVEncodingOption.lpcm = 'lpcm';
  AVEncodingOption.ima4 = 'ima4';
  AVEncodingOption.aac = 'aac';
  AVEncodingOption.MAC3 = 'MAC3';
  AVEncodingOption.MAC6 = 'MAC6';
  AVEncodingOption.ulaw = 'ulaw';
  AVEncodingOption.alaw = 'alaw';
  AVEncodingOption.mp1 = 'mp1';
  AVEncodingOption.mp2 = 'mp2';
  AVEncodingOption.alac = 'alac';
  AVEncodingOption.amr = 'amr';
  AVEncodingOption.flac = 'flac';
  AVEncodingOption.opus = 'opus';
})(AVEncodingOption || (AVEncodingOption = {}));
export let AVEncoderAudioQualityIOSType;
(function(AVEncoderAudioQualityIOSType) {
  AVEncoderAudioQualityIOSType[AVEncoderAudioQualityIOSType.min = 0] = 'min';
  AVEncoderAudioQualityIOSType[AVEncoderAudioQualityIOSType.low = 32] = 'low';
  AVEncoderAudioQualityIOSType[AVEncoderAudioQualityIOSType.medium = 64] = 'medium';
  AVEncoderAudioQualityIOSType[AVEncoderAudioQualityIOSType.high = 96] = 'high';
  AVEncoderAudioQualityIOSType[AVEncoderAudioQualityIOSType.max = 127] = 'max';
})(AVEncoderAudioQualityIOSType || (AVEncoderAudioQualityIOSType = {}));
const pad = (num) => {
  return ('0' + num).slice(-2);
};
class AudioRecorderPlayer {
  constructor() {
    this.mmss = (secs) => {
      let minutes = Math.floor(secs / 60);
      secs = secs % 60;
      minutes = minutes % 60;
      // minutes = ('0' + minutes).slice(-2);
      // secs = ('0' + secs).slice(-2);
      return pad(minutes) + ':' + pad(secs);
    };
    this.mmssss = (milisecs) => {
      const secs = Math.floor(milisecs / 1000);
      const minutes = Math.floor(secs / 60);
      const seconds = secs % 60;
      const miliseconds = Math.floor((milisecs % 1000) / 10);
      return pad(minutes) + ':' + pad(seconds) + ':' + pad(miliseconds);
    };
    /**
         * set listerner from native module for recorder.
         * @returns {callBack(e: any)}
         */
    this.addRecordBackListener = (e) => {
      if (Platform.OS === 'android') {
        this._recorderSubscription = DeviceEventEmitter.addListener('rn-recordback', e);
      } else {
        const myModuleEvt = new NativeEventEmitter(RNAudioRecorderPlayer);
        this._recorderSubscription = myModuleEvt.addListener('rn-recordback', e);
      }
    };
    /**
         * remove listener for recorder.
         * @returns {void}
         */
    this.removeRecordBackListener = () => {
      if (this._recorderSubscription) {
        this._recorderSubscription.remove();
        this._recorderSubscription = null;
      }
    };
    /**
         * set listener from native module for player.
         * @returns {callBack(e: Event)}
         */
    this.addPlayBackListener = (e) => {
      if (Platform.OS === 'android') {
        this._playerSubscription = DeviceEventEmitter.addListener('rn-playback', e);
      } else {
        const myModuleEvt = new NativeEventEmitter(RNAudioRecorderPlayer);
        this._playerSubscription = myModuleEvt.addListener('rn-playback', e);
      }
    };
    /**
         * remove listener for player.
         * @returns {void}
         */
    this.removePlayBackListener = () => {
      if (this._playerSubscription) {
        this._playerSubscription.remove();
        this._playerSubscription = null;
      }
    };
    /**
         * start recording with param.
         * @param {string} uri audio uri.
         * @returns {Promise<string>}
         */
    this.startRecorder = async (uri, audioSets) => {
      if (!uri) {
        uri = 'DEFAULT';
      }
      if (!this._isRecording) {
        this._isRecording = true;
        return RNAudioRecorderPlayer.startRecorder(uri, audioSets);
      }
      return 'Already recording';
    };
    /**
         * stop recording.
         * @returns {Promise<string>}
         */
    this.stopRecorder = async () => {
      if (this._isRecording) {
        this._isRecording = false;
        return RNAudioRecorderPlayer.stopRecorder();
      }
      return 'Already stopped';
    };
    /**
         * resume playing.
         * @returns {Promise<string>}
         */
    this.resumePlayer = async () => {
      if (!this._isPlaying) { return 'No audio playing'; }
      if (this._hasPaused) {
        this._hasPaused = false;
        return RNAudioRecorderPlayer.resumePlayer();
      }
      return 'Already playing';
    };
    /**
         * start playing with param.
         * @param {string} uri audio uri.
         * @returns {Promise<string>}
         */
    this.startPlayer = async (uri, options) => {
      if (!uri) {
        uri = 'DEFAULT';
      }
      if (!this._isPlaying || this._hasPaused) {
        this._isPlaying = true;
        this._hasPaused = false;
        return RNAudioRecorderPlayer.startPlayer(uri, options);
      }
    };
    /**
         * stop playing.
         * @returns {Promise<string>}
         */
    this.stopPlayer = async () => {
      if (this._isPlaying) {
        this._isPlaying = false;
        this._hasPaused = false;
        return RNAudioRecorderPlayer.stopPlayer();
      }
      return 'Already stopped playing';
    };
    /**
         * pause playing.
         * @returns {Promise<string>}
         */
    this.pausePlayer = async () => {
      if (!this._isPlaying) { return 'No audio playing'; }
      if (!this._hasPaused) {
        this._hasPaused = true;
        return RNAudioRecorderPlayer.pausePlayer();
      }
    };
    /**
         * seek to.
         * @param {number} time position seek to in second.
         * @returns {Promise<string>}
         */
    this.seekToPlayer = async (time) => {
      if (Platform.OS === 'ios') {
        time = time / 1000;
      }
      return RNAudioRecorderPlayer.seekToPlayer(time);
    };
    /**
         * set volume.
         * @param {number} setVolume set volume.
         * @returns {Promise<string>}
         */
    this.setVolume = async (volume) => {
      if (volume < 0 || volume > 1) {
        throw new Error('Value of volume should be between 0.0 to 1.0');
      }
      return RNAudioRecorderPlayer.setVolume(volume);
    };
    /**
         * set subscription duration.
         * @param {number} sec subscription callback duration in seconds.
         * @returns {Promise<string>}
         */
    this.setSubscriptionDuration = async (sec) => {
      return RNAudioRecorderPlayer.setSubscriptionDuration(sec);
    };
  }

  getOutputs(callback) {
    RNAudioRecorderPlayer.getOutputs((outputs) => {
      callback(outputs);
    });
  }
  ;
}
export default AudioRecorderPlayer;
