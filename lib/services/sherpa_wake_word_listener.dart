import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class SherpaWakeWordListener {
  static const _assetDirectory = 'assets/sherpa_kws';
  static const _sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();
  sherpa.KeywordSpotter? _spotter;
  sherpa.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _audioSubscription;
  Future<void>? _captureStopFuture;
  bool _running = false;
  bool _starting = false;
  bool _detectionInProgress = false;
  bool _disposed = false;
  String? _wakePhrase;
  Future<void> Function(String phrase)? _onWakeWord;
  void Function(Object error, StackTrace stackTrace)? _onError;

  bool get isRunning => _running;

  Future<void> start({
    required String wakePhrase,
    required Future<void> Function(String phrase) onWakeWord,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) async {
    if (_disposed) throw StateError('Wake-word listener has been disposed.');
    if (_starting) return;
    final normalizedPhrase = wakePhrase.trim();
    if (normalizedPhrase.isEmpty) {
      throw ArgumentError.value(wakePhrase, 'wakePhrase', 'Cannot be empty.');
    }

    _onWakeWord = onWakeWord;
    _onError = onError;
    if (_running && _wakePhrase == normalizedPhrase) return;

    _starting = true;
    try {
      await pause();
      if (_wakePhrase != normalizedPhrase || _spotter == null) {
        await _releaseSpotter();
        await _createSpotter(normalizedPhrase);
      }
      _detectionInProgress = false;
      await _startCapture();
      _wakePhrase = normalizedPhrase;
      _running = true;
    } catch (_) {
      await _stopCapture();
      rethrow;
    } finally {
      _starting = false;
    }
  }

  Future<void> pause() async {
    _running = false;
    await _stopCapture();
    final stream = _stream;
    final spotter = _spotter;
    if (stream != null && spotter != null) {
      spotter.reset(stream);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await pause();
    await _releaseSpotter();
    await _recorder.dispose();
  }

  Future<void> _createSpotter(String wakePhrase) async {
    await sherpa.initBindingsAsync();
    final modelDirectory = await getApplicationSupportDirectory();
    final encoder = await _copyModel('encoder.int8.onnx', modelDirectory);
    final decoder = await _copyModel('decoder.onnx', modelDirectory);
    final joiner = await _copyModel('joiner.int8.onnx', modelDirectory);
    final tokens = await _copyModel('tokens.txt', modelDirectory);
    final lexicon = await rootBundle.loadString('$_assetDirectory/en.phone');
    final keyword = _keywordTokens(wakePhrase, lexicon);
    final keywordBytes = utf8.encode(keyword);

    final spotter = sherpa.KeywordSpotter(
      sherpa.KeywordSpotterConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: encoder,
            decoder: decoder,
            joiner: joiner,
          ),
          tokens: tokens,
          numThreads: 1,
          debug: false,
        ),
        keywordsBuf: keyword,
        keywordsBufSize: keywordBytes.length,
        keywordsThreshold: 0.25,
      ),
    );

    _spotter = spotter;
    _stream = spotter.createStream();
  }

  Future<String> _copyModel(String name, Directory destination) async {
    final path = '${destination.path}${Platform.pathSeparator}$name';
    final file = File(path);
    if (!await file.exists()) {
      final data = await rootBundle.load('$_assetDirectory/$name');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return path;
  }

  String _keywordTokens(String wakePhrase, String lexicon) {
    final words = wakePhrase
        .toUpperCase()
        .replaceAll(RegExp(r"[^A-Z0-9' ]"), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      throw FormatException('Wake name has no supported English letters.');
    }

    final pronunciations = <String, String>{};
    for (final line in const LineSplitter().convert(lexicon)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length > 1 && !parts.first.contains('(')) {
        pronunciations.putIfAbsent(parts.first, () => parts.skip(1).join(' '));
      }
    }

    final phones = <String>[];
    for (final word in words) {
      final pronunciation = pronunciations[word];
      if (pronunciation == null) {
        throw FormatException(
          'The Sherpa wake-word model has no pronunciation for "$word".',
        );
      }
      phones.add(pronunciation);
    }

    final label = words.join('_');
    return '${phones.join(' ')} :1.0 #0.25 @$label\n';
  }

  Future<void> _startCapture() async {
    if (!await _recorder.hasPermission(request: false)) {
      throw StateError('Microphone permission is not granted.');
    }

    final audio = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceRecognition,
        ),
        audioInterruption: AudioInterruptionMode.pause,
        streamBufferSize: 3200,
      ),
    );
    _audioSubscription = audio.listen(
      _processAudio,
      onError: (Object error, StackTrace stackTrace) {
        unawaited(_handleCaptureError(error, stackTrace));
      },
      onDone: () {
        if (_running && !_detectionInProgress) {
          unawaited(
            _handleCaptureError(
              StateError('Microphone audio stream ended unexpectedly.'),
              StackTrace.current,
            ),
          );
        }
      },
      cancelOnError: true,
    );
  }

  void _processAudio(Uint8List bytes) {
    if (!_running || _detectionInProgress || bytes.length < 2) return;
    final spotter = _spotter;
    final stream = _stream;
    if (spotter == null || stream == null) return;

    final sampleCount = bytes.length ~/ 2;
    final data = ByteData.sublistView(bytes);
    final samples = Float32List(sampleCount);
    for (var index = 0; index < sampleCount; index++) {
      samples[index] = data.getInt16(index * 2, Endian.little) / 32768.0;
    }

    try {
      stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      while (spotter.isReady(stream)) {
        spotter.decode(stream);
        final keyword = spotter.getResult(stream).keyword.trim();
        if (keyword.isNotEmpty) {
          _detectionInProgress = true;
          _running = false;
          unawaited(_deliverWakeWord(keyword));
          return;
        }
      }
    } catch (error, stackTrace) {
      unawaited(_handleCaptureError(error, stackTrace));
    }
  }

  Future<void> _deliverWakeWord(String keyword) async {
    try {
      await _stopCapture();
      final callback = _onWakeWord;
      if (callback != null && !_disposed) {
        await callback(keyword.replaceAll('_', ' '));
      }
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
  }

  Future<void> _handleCaptureError(Object error, StackTrace stackTrace) async {
    if (!_running) return;
    _running = false;
    await _stopCapture();
    _reportError(error, stackTrace);
  }

  void _reportError(Object error, StackTrace stackTrace) {
    if (_disposed) return;
    _onError?.call(error, stackTrace);
  }

  Future<void> _stopCapture() {
    final current = _captureStopFuture;
    if (current != null) return current;

    final stopping = _stopCaptureImpl();
    _captureStopFuture = stopping;
    return stopping.whenComplete(() => _captureStopFuture = null);
  }

  Future<void> _stopCaptureImpl() async {
    final subscription = _audioSubscription;
    _audioSubscription = null;
    await subscription?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> _releaseSpotter() async {
    _stream?.free();
    _stream = null;
    _spotter?.free();
    _spotter = null;
  }
}
