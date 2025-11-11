// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:auto_size_text/auto_size_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class PreJoiningDialog extends StatefulWidget {
  const PreJoiningDialog({
    super.key,
    this.width,
    this.height,
    required this.token,
    required this.channelName,
    required this.appId,
    this.userName,
    this.profileImage,
  });

  final double? width;
  final double? height;
  final String token;
  final String channelName;
  final String appId;
  final String? userName;
  final String? profileImage;
  @override
  State<PreJoiningDialog> createState() => _PreJoiningDialogState();
}

class _PreJoiningDialogState extends State<PreJoiningDialog> {
  bool _isMicEnabled = false;
  bool _isCameraEnabled = false;
  bool _isJoining = false;

  @override
  void initState() {
    _getPermissions();
    super.initState();
  }

  Future<void> _getMicPermissions() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final micPermission = await Permission.microphone.request();
      if (micPermission == PermissionStatus.granted) {
        setState(() => _isMicEnabled = true);
      }
    } else {
      setState(() => _isMicEnabled = !_isMicEnabled);
    }
  }

  Future<void> _getCameraPermissions() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission == PermissionStatus.granted) {
        setState(() => _isCameraEnabled = true);
      }
    } else {
      setState(() => _isCameraEnabled = !_isCameraEnabled);
    }
  }

  Future<void> _getPermissions() async {
    await _getMicPermissions();
    await _getCameraPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.80,
        height: MediaQuery.of(context).size.height * 0.4,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Joining Call',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'You are about to join a video call. Please set your mic and camera preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () {
                    if (_isMicEnabled) {
                      setState(() => _isMicEnabled = false);
                    } else {
                      _getMicPermissions();
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: _isMicEnabled
                            ? const Color.fromARGB(255, 49, 229, 142)
                            : Colors.redAccent,
                        radius: 32.0,
                        child: Icon(
                          _isMicEnabled
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _isMicEnabled ? 'Mic: On' : 'Mic: Off',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () {
                    if (_isCameraEnabled) {
                      setState(() => _isCameraEnabled = false);
                    } else {
                      _getCameraPermissions();
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: _isCameraEnabled
                            ? const Color.fromARGB(255, 49, 229, 142)
                            : Colors.redAccent,
                        radius: 32.0,
                        child: Icon(
                          _isCameraEnabled
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _isCameraEnabled ? 'Camera: On' : 'Camera: Off',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isJoining ? null : _joinCall,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              child: _isJoining
                  ? CircularProgressIndicator()
                  : Text(
                      'Join',
                      style: TextStyle(fontSize: 20),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinCall() async {
    setState(() => _isJoining = true);

    setState(() => _isJoining = false);
    if (context.mounted) {
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallPage(
            appId: widget.appId,
            token: widget.token,
            channelName: widget.channelName,
            isMicEnabled: _isMicEnabled,
            isVideoEnabled: _isCameraEnabled,
            userName: widget.userName ?? 'Blupry',
            profileImage: widget.profileImage ??
                'https://res.cloudinary.com/dcato1y8g/image/upload/v1747920945/1747920944488000_ld6xer.jpg',
          ),
        ),
      );
    }
  }
}

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({
    Key? key,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.isMicEnabled,
    required this.isVideoEnabled,
    this.userName,
    this.profileImage,
  }) : super(key: key);

  final String appId;
  final String token;
  final String channelName;
  final bool isMicEnabled;
  final bool isVideoEnabled;
  final String? userName;
  final String? profileImage;

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late RtcEngine _agoraEngine;
  List<AgoraUser> _users = [];
  late int _currentUid;
  bool _localUserJoined = false;
  bool _isMicEnabled = true;
  bool _isVideoEnabled = true;
  late double _viewAspectRatio;
  final Map<int, Map<String, String?>> _userProfiles = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _isMicEnabled = widget.isMicEnabled;
    _isVideoEnabled = widget.isVideoEnabled;
    _listenToParticipantInfo();

    initAgora();
  }

  @override
  void dispose() {
    _firestore
        .collection('channels')
        .doc(widget.channelName)
        .collection('participants')
        .doc('uid_$_currentUid')
        .delete();

    _users.clear();
    _disposeAgora();
    _agoraEngine.stopPreview();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    await _agoraEngine.leaveChannel();
    _agoraEngine.release();
  }

  void _listenToParticipantInfo() {
    FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelName)
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid = data['uid'];
        final name = data['userName'];
        final image = data['profileImage'];

        if (uid != null && name != null) {
          setState(() {
            _userProfiles[uid] = {
              'name': name,
              'image': image,
            };

            final index = _users.indexWhere((u) => u.uid == uid);
            if (index != -1) {
              _users[index].name = name;
              _users[index].profileImage = image;
            }
          });
        }
      }
    });
  }

  Future<void> initAgora() async {
    if (kIsWeb) {
      _viewAspectRatio = 3 / 2;
    } else if (Platform.isAndroid || Platform.isIOS) {
      _viewAspectRatio = 2 / 3;
    } else {
      _viewAspectRatio = 3 / 2;
    }
    await [Permission.microphone, Permission.camera].request();

    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine.initialize(RtcEngineContext(
      appId: widget.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    if (!kIsWeb) {
      await _agoraEngine.setDualStreamMode(
        mode: SimulcastStreamMode.enableSimulcastStream,
      );
    }

    await _agoraEngine.setVideoEncoderConfiguration(
      VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 320, height: 180),
        frameRate: 15,
        bitrate: 200,
      ),
    );

    await _agoraEngine.setVideoEncoderConfiguration(
      VideoEncoderConfiguration(
        orientationMode: OrientationMode.orientationModeAdaptive,
        dimensions: VideoDimensions(width: 640, height: 360),
      ),
    );

    _agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          setState(() {
            _localUserJoined = true;

            _currentUid = connection.localUid!;

            _users.removeWhere((u) => u.uid == _currentUid);
            _users.add(
              AgoraUser(
                uid: _currentUid,
                isAudioEnabled: _isMicEnabled,
                isVideoEnabled: _isVideoEnabled,
                view: _isVideoEnabled
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _agoraEngine,
                          canvas: VideoCanvas(uid: 0),
                        ),
                      )
                    : null,
                name: widget.userName,
                profileImage: widget.profileImage,
              ),
            );
          });
          final localUid = connection.localUid ?? 0;

          await _firestore
              .collection('channels')
              .doc(widget.channelName)
              .collection('participants')
              .doc('uid_$localUid')
              .set({
            'uid': localUid,
            'userName': widget.userName,
            'profileImage': widget.profileImage,
          });

          setState(() {
            _userProfiles[localUid] = {
              'name': widget.userName,
              'image': widget.profileImage,
            };
          });

          for (var user in _users) {
            if (user.uid != _currentUid) {
              _agoraEngine.setRemoteVideoStreamType(
                uid: user.uid,
                streamType: VideoStreamType.videoStreamLow,
              );
            }
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          final profile = _userProfiles[remoteUid];
          final name = profile?['name'];
          final image = profile?['image'];

          setState(() {
            _users.add(
              AgoraUser(
                uid: remoteUid,
                isAudioEnabled: true,
                isVideoEnabled: true,
                name: name,
                profileImage: image,
                view: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _agoraEngine,
                    canvas: VideoCanvas(uid: remoteUid),
                    connection: RtcConnection(channelId: widget.channelName),
                  ),
                ),
              ),
            );
            _users = List.from(_users);
          });
        },
        onRemoteVideoStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed) {
          if (state == RemoteVideoState.remoteVideoStateDecoding &&
              reason ==
                  RemoteVideoStateReason.remoteVideoStateReasonRemoteUnmuted) {
            setState(() {
              final index = _users.indexWhere((u) => u.uid == remoteUid);
              if (index != -1) {
                _users[index].view = AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _agoraEngine,
                    canvas: VideoCanvas(uid: remoteUid),
                    connection: RtcConnection(channelId: widget.channelName),
                  ),
                );
              }
            });
          }
        },
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          setState(() {
            final index = _users.indexWhere((u) => u.uid == remoteUid);
            if (index != -1) {
              _users[index].isVideoEnabled = !muted;
            }
          });
        },
        onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
          setState(() {
            final index = _users.indexWhere((u) => u.uid == remoteUid);
            if (index != -1) {
              _users[index].isAudioEnabled = !muted;
            }
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, _) {
          setState(() {
            _users.removeWhere((user) => user.uid == remoteUid);
          });
        },
        onFirstRemoteVideoFrame: (RtcConnection connection, int uid, int width,
            int height, int elapsed) {
          debugPrint('LOG::firstRemoteVideoFrame: $uid ${width}x$height');
          final index = _users.indexWhere((u) => u.uid == uid);
          if (index != -1) {
            setState(() {
              _users[index]
                ..isVideoEnabled = true
                ..view = AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _agoraEngine,
                    canvas: VideoCanvas(uid: uid),
                    connection: RtcConnection(channelId: widget.channelName),
                  ),
                );
            });
          }
        },
        onFirstLocalVideoFrame:
            (VideoSourceType source, int width, int height, int elapsed) {
          debugPrint(
              'LOG::firstLocalVideoFrame: $_currentUid ${width}x$height');
          final index = _users.indexWhere((u) => u.uid == _currentUid);
          if (index != -1) {
            setState(() {
              _users[index]
                ..isVideoEnabled = _isVideoEnabled
                ..view = AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _agoraEngine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                );
            });
          }
        },
      ),
    );

    await _agoraEngine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster);
    if (_isVideoEnabled) await _agoraEngine.enableVideo();
    if (_isVideoEnabled) await _agoraEngine.startPreview();

    await _agoraEngine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _onCallEnd() async {
    await _agoraEngine.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onToggleAudio() async {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
      _users.firstWhere((u) => u.uid == _currentUid).isAudioEnabled =
          _isMicEnabled;
    });
    _agoraEngine.muteLocalAudioStream(!_isMicEnabled);
  }

  Future<void> _onToggleCamera() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
      for (AgoraUser user in _users) {
        if (user.uid == _currentUid) {
          setState(() => user.isVideoEnabled = _isVideoEnabled);
        }
      }
    });
    _agoraEngine.muteLocalVideoStream(!_isVideoEnabled);
  }

  Future<void> _onSwitchCamera() async {
    if (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Camera switching is not supported on web browsers.')),
      );
      return;
    }

    try {
      await _agoraEngine.switchCamera();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to switch camera: $e')),
      );
    }
  }

  List<int> _createLayout(int n) {
    if (n == 0) return [0];

    int rows = sqrt(n).ceil();
    int columns = (n / rows).ceil();
    List<int> layout = List<int>.filled(rows, columns);
    int remaining = rows * columns - n;
    for (int i = 0; i < remaining; i++) {
      layout[layout.length - 1 - i] -= 1;
    }
    return layout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.meeting_room_rounded, color: Colors.white54),
            const SizedBox(width: 6),
            const Text('Channel: ', style: TextStyle(color: Colors.white54)),
            Text(widget.channelName,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white54),
                const SizedBox(width: 6),
                Text('${_users.length}',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final isPortrait = orientation == Orientation.portrait;
                  _viewAspectRatio = isPortrait ? 2 / 3 : 3 / 2;
                  final layout = _createLayout(_users.length);
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: AgoraVideoLayout(
                      key: ValueKey(_users.length),
                      users: _users,
                      views: layout,
                      viewAspectRatio: _viewAspectRatio,
                    ),
                  );
                },
              ),
            ),
            CallActionsRow(
              isMicEnabled: _isMicEnabled,
              isVideoEnabled: _isVideoEnabled,
              onCallEnd: _onCallEnd,
              onToggleAudio: _onToggleAudio,
              onToggleCamera: _onToggleCamera,
              onSwitchCamera: _onSwitchCamera,
            ),
          ],
        ),
      ),
    );
  }
}

class AgoraVideoLayout extends StatelessWidget {
  const AgoraVideoLayout({
    super.key,
    required List<AgoraUser> users,
    required List<int> views,
    required double viewAspectRatio,
  })  : _users = users,
        _views = views,
        _viewAspectRatio = viewAspectRatio;

  final List<AgoraUser> _users;
  final List<int> _views;
  final double _viewAspectRatio;

  @override
  Widget build(BuildContext context) {
    int totalCount = _views.reduce((value, element) => value + element);
    int rows = _views.length;
    int columns = _views.reduce(max);

    List<Widget> rowsList = [];
    for (int i = 0; i < rows; i++) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < columns; j++) {
        int index = i * columns + j;
        if (index < totalCount) {
          rowChildren.add(CustomAgoraVideoView(
            user: _users.elementAt(index),
            viewAspectRatio: _viewAspectRatio,
          ));
        } else {
          rowChildren.add(
            const SizedBox.shrink(),
          );
        }
      }
      rowsList.add(
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: rowChildren,
          ),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowsList,
    );
  }
}

class CustomAgoraVideoView extends StatelessWidget {
  const CustomAgoraVideoView({
    super.key,
    required double viewAspectRatio,
    required AgoraUser user,
  })  : _viewAspectRatio = viewAspectRatio,
        _user = user;

  final double _viewAspectRatio;
  final AgoraUser _user;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: AspectRatio(
          aspectRatio: _viewAspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _user.isAudioEnabled ?? false ? Colors.blue : Colors.red,
                width: 2.0,
              ),
            ),
            child: Stack(
              children: [
                if (_user.view == null)
                  Center(child: Text("Waiting for video...")),
                if (_user.view != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Opacity(
                      opacity: (_user.isVideoEnabled ?? true) ? 1.0 : 0.0,
                      child: _user.view,
                    ),
                  ),
                if (!(_user.isVideoEnabled ?? true))
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.videocam_off,
                              color: Colors.white70, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Camera Off',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!(_user.isAudioEnabled ?? true))
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.mic_off,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                if (_user.profileImage != null || _user.name != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Row(
                      children: [
                        if (_user.profileImage != null)
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(_user.profileImage!),
                            backgroundColor: Colors.white12,
                          ),
                        if (_user.name != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _user.name!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Made by Blupry.io
class AgoraUser {
  final int uid;
  String? name;
  String? profileImage;
  bool? isAudioEnabled;
  bool? isVideoEnabled;
  Widget? view;

  AgoraUser({
    required this.uid,
    this.name,
    this.profileImage,
    this.isAudioEnabled,
    this.isVideoEnabled,
    this.view,
  });
}

class CallActionsRow extends StatefulWidget {
  final bool isMicEnabled;
  final bool isVideoEnabled;
  final Future Function() onCallEnd;
  final Future Function() onToggleAudio;
  final Future Function() onToggleCamera;
  final Future Function() onSwitchCamera;

  const CallActionsRow({
    super.key,
    required this.isMicEnabled,
    required this.isVideoEnabled,
    required this.onCallEnd,
    required this.onToggleAudio,
    required this.onToggleCamera,
    required this.onSwitchCamera,
  });

  @override
  State<CallActionsRow> createState() => _CallActionsRowState();
}

class _CallActionsRowState extends State<CallActionsRow> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          CallActionButton(
            callEnd: true,
            icon: Icons.call_end,
            onTap: widget.onCallEnd,
          ),
          CallActionButton(
            icon: widget.isMicEnabled ? Icons.mic : Icons.mic_off,
            isEnabled: widget.isMicEnabled,
            onTap: widget.onToggleAudio,
          ),
          CallActionButton(
            icon: widget.isVideoEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            isEnabled: widget.isVideoEnabled,
            onTap: widget.onToggleCamera,
          ),
          CallActionButton(
            icon: Icons.cameraswitch_rounded,
            onTap: widget.onSwitchCamera,
          ),
        ],
      ),
    );
  }
}

//Blupry.com No-code marketplace, custom template and support!
class CallActionButton extends StatelessWidget {
  const CallActionButton({
    super.key,
    this.onTap,
    required this.icon,
    this.callEnd = false,
    this.isEnabled = true,
  });

  final Function()? onTap;
  final IconData icon;
  final bool callEnd;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: callEnd
            ? Colors.redAccent
            : isEnabled
                ? Colors.grey.shade800
                : Colors.white,
        radius: callEnd ? 28 : 24,
        child: Icon(
          icon,
          size: callEnd ? 26 : 22,
          color: callEnd
              ? Colors.white
              : isEnabled
                  ? Colors.white
                  : Colors.grey.shade600,
        ),
      ),
    );
  }
}

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
