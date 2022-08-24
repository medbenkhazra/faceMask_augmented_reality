import 'dart:io';

import 'package:avatar_view/avatar_view.dart';
import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:open_file/open_file.dart';

class CameraWithFilters extends StatefulWidget {
  const CameraWithFilters({Key? key}) : super(key: key);

  @override
  State<CameraWithFilters> createState() => _CameraWithFiltersState();
}

class _CameraWithFiltersState extends State<CameraWithFilters> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: const Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final DeepArController _controller;
  String version = '';
  bool _isFaceMask = false;
  bool _isFilter = false;

  final List<String> _effectsList = [];
  final List<String> _maskList = [];
  final List<String> _filterList = [];
  int _effectIndex = 0;
  int _maskIndex = 0;
  int _filterIndex = 0;
  //int currentPage = 0;

  final String _assetEffectsPath = 'assets/effects/';

  @override
  void initState() {
    _controller = DeepArController();
    _controller
        .initialize(
          androidLicenseKey:
              "56453f3228e07902dd2f529056d337714ceceea701f9bd251718f67a61d799487f20c1535504c8b4",
          iosLicenseKey: "---iOS key---",
          resolution: Resolution.high,
        )
        .then((value) => setState(() {}));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _initEffects();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        _controller.isInitialized
            ? DeepArPreview(_controller)
            : const Center(
                child: Text("Loading..."),
              ),
        _topMediaOptions(),
        _bottomFilterOptions(),
        // _bottomMediaOptions(),
      ],
    ));
  }

  // flip, face mask, filter, flash
  Positioned _topMediaOptions() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () async {
              await _controller.toggleFlash();
              setState(() {});
            },
            color: Colors.white70,
            iconSize: 40,
            icon:
                Icon(_controller.flashState ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: () async {
              _isFaceMask = !_isFaceMask;
              if (_isFaceMask) {
                _controller.switchFaceMask(_maskList[_maskIndex]);
              } else {
                _controller.switchFaceMask("null");
              }

              setState(() {});
            },
            color: Colors.white70,
            iconSize: 40,
            icon: Icon(
              _isFaceMask
                  ? Icons.face_retouching_natural_rounded
                  : Icons.face_retouching_off,
            ),
          ),
          IconButton(
            onPressed: () async {
              _isFilter = !_isFilter;
              if (_isFilter) {
                _controller.switchFilter(_filterList[_filterIndex]);
              } else {
                _controller.switchFilter("null");
              }
              setState(() {});
            },
            color: Colors.white70,
            iconSize: 40,
            icon: Icon(
              _isFilter ? Icons.filter_hdr : Icons.filter_hdr_outlined,
            ),
          ),
          IconButton(
              onPressed: () {
                _controller.flipCamera();
              },
              iconSize: 50,
              color: Colors.white70,
              icon: const Icon(Icons.cameraswitch))
        ],
      ),
    );
  }

  Positioned _bottomFilterOptions() {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_maskList.length, (index) {
            _isFaceMask = _maskIndex == index;
            return GestureDetector(
              onTap: () {
                _maskIndex = index;
                _controller.switchFaceMask(_maskList[index - 1]);
                setState(() {});
              },
              child: AvatarView(
                radius: _isFaceMask ? 55 : 30,
                borderColor: Colors.white,
                borderWidth: 3,
                isOnlyText: false,
                backgroundColor: Colors.pink[400],
                imagePath: "assets/images/${index.toString()}.png",
                placeHolder: Icon(
                  Icons.person,
                  size: 45,
                ),
                errorWidget: Container(
                  child: Icon(
                    Icons.error,
                    size: 45,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // prev, record, screenshot, next
  /// Sample option which can be performed
  Positioned _bottomMediaOptions() {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                iconSize: 60,
                onPressed: () {
                  if (_isFaceMask) {
                    String prevMask = _getPrevMask();
                    _controller.switchFaceMask(prevMask);
                  } else if (_isFilter) {
                    String prevFilter = _getPrevFilter();
                    _controller.switchFilter(prevFilter);
                  } else {
                    String prevEffect = _getPrevEffect();
                    _controller.switchEffect(prevEffect);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white70,
                )),
            IconButton(
                onPressed: () async {
                  if (_controller.isRecording) {
                    File? file = await _controller.stopVideoRecording();
                    OpenFile.open(file.path);
                  } else {
                    await _controller.startVideoRecording();
                  }

                  setState(() {});
                },
                iconSize: 50,
                color: Colors.white70,
                icon: Icon(_controller.isRecording
                    ? Icons.videocam_sharp
                    : Icons.videocam_outlined)),
            const SizedBox(width: 20),
            IconButton(
                onPressed: () {
                  _controller.takeScreenshot().then((file) {
                    OpenFile.open(file.path);
                  });
                },
                color: Colors.white70,
                iconSize: 40,
                icon: const Icon(Icons.photo_camera)),
            IconButton(
                iconSize: 60,
                onPressed: () {
                  if (_isFaceMask) {
                    String nextMask = _getNextMask();
                    _controller.switchFaceMask(nextMask);
                  } else if (_isFilter) {
                    String nextFilter = _getNextFilter();
                    _controller.switchFilter(nextFilter);
                  } else {
                    String nextEffect = _getNextEffect();
                    _controller.switchEffect(nextEffect);
                  }
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                )),
          ],
        ),
      ),
    );
  }

  /// Add effects which are rendered via DeepAR sdk
  void _initEffects() {
    // Either get all effects
    _getEffectsFromAssets(context).then((values) {
      _effectsList.clear();
      _effectsList.addAll(values);

      _maskList.clear();
      // _maskList.add(_assetEffectsPath + 'flower_face.deepar');
      // _maskList.add(_assetEffectsPath + 'viking_helmet.deepar');
      _maskList.add(_assetEffectsPath + 'burning_effect.deepar');
      _maskList.add(_assetEffectsPath + '8bitHearts.deepar');

      _maskList.add(_assetEffectsPath + 'Elephant_Trunk.deepar');
      _maskList.add(_assetEffectsPath + 'Emotion_Meter.deepar');
      _maskList.add(_assetEffectsPath + 'Emotions_Exaggerator.deepar');

      _maskList.add(_assetEffectsPath + 'Fire_Effect.deepar');

      _maskList.add(_assetEffectsPath + 'flower_face.deepar');

      _maskList.add(_assetEffectsPath + 'galaxy_background.deepar');

      _maskList.add(_assetEffectsPath + 'Hope.deepar');

      _maskList.add(_assetEffectsPath + 'Humanoid.deepar');

      _maskList.add(_assetEffectsPath + 'MakeupLook.deepar');

      _maskList.add(_assetEffectsPath + 'Neon_Devil_Horns.deepar');

      _maskList.add(_assetEffectsPath + 'Ping_Pong.deepar');

      _maskList.add(_assetEffectsPath + 'Snail.deepar');

      _maskList.add(_assetEffectsPath + 'Split_View_Look.deepar');

      _maskList.add(_assetEffectsPath + 'Stallone.deepar');

      _maskList.add(_assetEffectsPath + 'Vendetta_Mask.deepar');

      _maskList.add(_assetEffectsPath + 'viking_helmet.deepar');

      _filterList.clear();
      _filterList.add(_assetEffectsPath + 'burning_effect.deepar');
      _filterList.add(_assetEffectsPath + 'Hope.deepar');

      _effectsList.removeWhere((element) => _maskList.contains(element));

      _effectsList.removeWhere((element) => _filterList.contains(element));
    });

    // OR

    // Only add specific effects
    // _effectsList.add(_assetEffectsPath+'burning_effect.deepar');
    // _effectsList.add(_assetEffectsPath+'flower_face.deepar');
    // _effectsList.add(_assetEffectsPath+'Hope.deepar');
    // _effectsList.add(_assetEffectsPath+'viking_helmet.deepar');
  }

  /// Get all deepar effects from assets
  ///
  Future<List<String>> _getEffectsFromAssets(BuildContext context) async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final filePaths = manifestMap.keys
        .where((path) => path.startsWith(_assetEffectsPath))
        .toList();
    return filePaths;
  }

  /// Get next effect
  String _getNextEffect() {
    _effectIndex < _effectsList.length ? _effectIndex++ : _effectIndex = 0;
    return _effectsList[_effectIndex];
  }

  /// Get previous effect
  String _getPrevEffect() {
    _effectIndex > 0 ? _effectIndex-- : _effectIndex = _effectsList.length;
    return _effectsList[_effectIndex];
  }

  /// Get next mask
  String _getNextMask() {
    _maskIndex < _maskList.length ? _maskIndex++ : _maskIndex = 0;
    return _maskList[_maskIndex];
  }

  /// Get previous mask
  String _getPrevMask() {
    _maskIndex > 0 ? _maskIndex-- : _maskIndex = _maskList.length;
    return _maskList[_maskIndex];
  }

  /// Get next filter
  String _getNextFilter() {
    _filterIndex < _filterList.length ? _filterIndex++ : _filterIndex = 0;
    return _filterList[_filterIndex];
  }

  /// Get previous filter
  String _getPrevFilter() {
    _filterIndex > 0 ? _filterIndex-- : _filterIndex = _filterList.length;
    return _filterList[_filterIndex];
  }
}
