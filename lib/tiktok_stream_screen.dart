import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class TikTokLiveStreamScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String liveTitle;

  const TikTokLiveStreamScreen({
    Key? key,
    required this.cameras,
    this.liveTitle = 'My Live Stream',
  }) : super(key: key);

  @override
  State<TikTokLiveStreamScreen> createState() => _TikTokLiveStreamScreenState();
}

class _TikTokLiveStreamScreenState extends State<TikTokLiveStreamScreen>
    with TickerProviderStateMixin {
  bool _isLiveStarted = true;
  int _viewerCount = 0;
  List<ChatMessage> _chatMessages = [];
  bool _isMuted = false;
  bool _isFlashOn = false;
  bool _showGiftAnimation = false;
  Timer? _viewerTimer;
  Timer? _messageTimer;
  late AnimationController _giftAnimationController;
  late Timer _durationTimer;
  late AnimationController _heartAnimationController;
  late AnimationController _liveTimerController;
  Duration _liveDuration = Duration.zero;
  List<FloatingHeart> _floatingHearts = [];
  double _networkQuality = 0.8; // 0-1 scale
  bool _showLiveOptions = false;
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  Future<void> _switchCamera() async {
    final currentCamera = _cameraController.description;
    final newCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection != currentCamera.lensDirection,
      orElse: () => currentCamera,
    );

    await _initializeCamera(newCamera);
  }

  Future<CameraDescription> _getOtherCamera(CameraDescription current) async {
    final cameras = await availableCameras();
    return cameras.firstWhere(
      (camera) => camera.lensDirection != current.lensDirection,
      orElse: () => current, // fallback to current if no other camera found
    );
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      if (_isCameraInitialized) {
        await _cameraController.dispose();
      }

      _cameraController = CameraController(camera, ResolutionPreset.high);

      await _cameraController.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera(widget.cameras.first);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isLiveStarted) {
        setState(() {
          _liveDuration = Duration(seconds: _liveDuration.inSeconds + 1);
        });
      }
    });

    // Live duration timer
    _liveTimerController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(() {
      setState(() {
        _liveDuration = Duration(seconds: _liveTimerController.value.toInt());
      });
    });
    _liveTimerController.forward();

    // Simulate increasing viewer count with better animation
    _viewerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _viewerCount += (1 + (_viewerCount ~/ 10));
          // Random hearts when viewers increase
          if (DateTime.now().second % 5 == 0) {
            _addRandomHeart();
          }
        });
      }
    });

    // Simulate incoming chat messages with better variety
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _chatMessages.length < 50) {
        _addRandomMessage();
      }
    });

    // Gift animation controller
    _giftAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _giftAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showGiftAnimation = false;
        });
        _giftAnimationController.reset();
      }
    });

    // Heart animation controller
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
      setState(() {
        _floatingHearts =
            _floatingHearts
                .where((heart) => heart.controller.value < 0.95)
                .toList();
      });
    });

    // Add initial messages
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        'TikTok',
        'Welcome to your LIVE! 🎉',
        isSystem: true,
        isModerator: true,
      );
      _addMessage('System', 'Waiting for viewers to join...', isSystem: true);
    });

    // Show gift animation after a few seconds
    Future.delayed(const Duration(seconds: 8), _triggerGiftAnimation);
    Future.delayed(const Duration(seconds: 12), _addRandomHeart);
  }

  void _addRandomHeart() {
    final heartColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.orange,
      Colors.white,
    ];

    final heartIcons = [
      Icons.favorite,
      Icons.favorite_border,
      Icons.heart_broken,
      Icons.emoji_emotions,
      Icons.star,
    ];

    final random = DateTime.now().millisecond % heartColors.length;

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500 + (random * 500)),
    )..forward();

    setState(() {
      _floatingHearts.add(
        FloatingHeart(
          color: heartColors[random],
          icon: heartIcons[random],
          controller: controller,
          xPosition: 0.1 + (random * 0.15),
        ),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {}
    });
  }

  void _triggerGiftAnimation() {
    if (mounted) {
      setState(() {
        _showGiftAnimation = true;
      });
      _giftAnimationController.forward();
    }
  }

  void _addRandomMessage() {
    final names = [
      'Alex',
      'Taylor',
      'Jordan',
      'Casey',
      'Sam',
      'Riley',
      'Jamie',
      'Avery',
      'Dylan',
      'Morgan',
    ];

    final badges = [null, 'VIP', 'Mod', 'New', 'Top Fan', 'Creator'];

    final messages = [
      'Hello from New York! 👋',
      'Love your content! ❤️',
      'First time catching your live!',
      'Can you say hi to me?',
      'Where are you from?',
      'Whats your favorite song?',
      '🔥🔥🔥',
      'How often do you go live?',
      'You re awesome!',
      'Followed you today!',
      'Just sent a gift! 🎁',
      'Can we collab sometime?',
      'OMG this is amazing!',
      'LOL 😂😂😂',
      'Team [yourname] for life!',
      'The energy here is crazy!',
    ];

    final randomName = names[DateTime.now().millisecond % names.length];
    final randomMessage = messages[DateTime.now().second % messages.length];
    final randomBadge = badges[DateTime.now().millisecond % badges.length];
    final isModerator = randomBadge == 'Mod' || randomBadge == 'Creator';

    _addMessage(
      randomName,
      randomMessage,
      badge: randomBadge,
      isModerator: isModerator,
    );
  }

  void _addMessage(
    String username,
    String message, {
    String? badge,
    bool isSystem = false,
    bool isModerator = false,
  }) {
    if (mounted) {
      setState(() {
        _chatMessages.insert(
          0,
          ChatMessage(
            username: username,
            message: message,
            badge: badge,
            isSystem: isSystem,
            isModerator: isModerator,
          ),
        );

        // Keep the chat history manageable
        if (_chatMessages.length > 50) {
          _chatMessages.removeLast();
        }
      });
    }
  }

  void _toggleLiveOptions() {
    setState(() {
      _showLiveOptions = !_showLiveOptions;
    });
  }

  void _endLive() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'End Live Stream?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to end your live stream?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  _liveTimerController.stop();
                  _durationTimer.cancel();
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous screen
                },
                child: Text('END', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _viewerTimer?.cancel();
    _messageTimer?.cancel();
    _durationTimer.cancel();
    _giftAnimationController.dispose();
    _heartAnimationController.dispose();
    _liveTimerController.dispose();
    for (var heart in _floatingHearts) {
      heart.controller.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview with gradient overlay
          Positioned.fill(
            child:
                _isCameraInitialized
                    ? CameraPreview(_cameraController)
                    : Center(child: CircularProgressIndicator()),
          ),
          // Floating hearts
          for (var heart in _floatingHearts)
            Positioned(
              left: MediaQuery.of(context).size.width * heart.xPosition,
              bottom: 100 + (100 * (1 - heart.controller.value)),
              child: Opacity(
                opacity: 1 - (heart.controller.value * 0.8),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: heart.controller,
                    curve: Curves.elasticOut,
                  ),
                  child: Icon(
                    heart.icon,
                    color: heart.color,
                    size: 30 + (30 * heart.controller.value),
                  ),
                ),
              ),
            ),

          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Top bar with enhanced features
                _buildEnhancedTopBar(),

                // Live options panel (conditionally shown)
                if (_showLiveOptions) _buildLiveOptionsPanel(),

                // Spacer to push chat to bottom
                Spacer(),

                // Chat messages overlay
                _buildEnhancedChatMessages(),

                // Bottom bar with improved buttons
                _buildEnhancedBottomBar(),
              ],
            ),
          ),

          // Gift animation overlay
          if (_showGiftAnimation) _buildEnhancedGiftAnimation(),
        ],
      ),
    );
  }

  Widget _buildEnhancedTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Profile info with better styling
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        // Profile picture with border
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.pink, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=80&q=80',
                            ),
                          ),
                        ),

                        // Live indicator with pulse animation
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: PulseAnimation(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YourUsername',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.liveTitle,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Spacer(),

              // Live duration and viewer count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Live duration
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(_liveDuration),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  // Viewer count with animation
                  AnimatedViewerCount(
                    count: _viewerCount,
                    duration: Duration(milliseconds: 500),
                  ),
                ],
              ),

              SizedBox(width: 12),

              // Network quality indicator
              _buildNetworkQualityIndicator(),

              SizedBox(width: 12),

              // Close button with better styling
              GestureDetector(
                onTap: _endLive,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          // Battery saver indicator
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // Add live goal functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Add Live Goal clicked'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Add Live Goal',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkQualityIndicator() {
    Color qualityColor;
    IconData qualityIcon;

    if (_networkQuality > 0.7) {
      qualityColor = Colors.green;
      qualityIcon = Icons.wifi;
    } else if (_networkQuality > 0.4) {
      qualityColor = Colors.orange;
      qualityIcon = Icons.wifi_2_bar;
    } else {
      qualityColor = Colors.red;
      qualityIcon = Icons.wifi_1_bar;
    }

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(qualityIcon, color: qualityColor, size: 18),
    );
  }

  Widget _buildLiveOptionsPanel() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Live options title
          Row(
            children: [
              Text(
                'LIVE OPTIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: _toggleLiveOptions,
              ),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.2)),

          // Options grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildLiveOptionItem(Icons.star, 'Goals', Colors.purple),
              _buildLiveOptionItem(Icons.people, 'Guests', Colors.blue),
              _buildLiveOptionItem(Icons.security, 'Mods', Colors.green),
              _buildLiveOptionItem(
                Icons.filter_vintage,
                'Effects',
                Colors.pink,
              ),
              _buildLiveOptionItem(Icons.event, 'Events', Colors.orange),
              _buildLiveOptionItem(
                Icons.notifications,
                'Alerts',
                Colors.yellow,
              ),
              _buildLiveOptionItem(Icons.qr_code, 'QR', Colors.teal),
              _buildLiveOptionItem(Icons.settings, 'Settings', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveOptionItem(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildEnhancedChatMessages() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      width: MediaQuery.of(context).size.width * 0.8,
      padding: EdgeInsets.only(left: 16, bottom: 16),
      child: ListView.builder(
        reverse: true,
        itemCount: _chatMessages.length,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final message = _chatMessages[index];
          return ChatBubble(
            message: message,
            onTap: () {
              // Implement pin message functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pinned: ${message.message}'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEnhancedGiftAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: _giftAnimationController,
        builder: (context, child) {
          final scale = Tween<double>(begin: 0.5, end: 1.2).animate(
            CurvedAnimation(
              parent: _giftAnimationController,
              curve: Curves.elasticOut,
            ),
          );

          final opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: _giftAnimationController,
              curve: Interval(0.6, 1.0),
            ),
          );

          return Opacity(
            opacity: opacity.value,
            child: Transform.scale(
              scale: scale.value,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink.withOpacity(0.8),
                      Colors.purple.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 48,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Taylor sent TikTok Universe!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'x100',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1,000 coins',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEnhancedActionButton(
            Icons.flip_camera_ios,
            Colors.white,
            onPressed: _switchCamera, // Changed to use new method
          ),
          _buildEnhancedActionButton(
            _isMuted ? Icons.mic_off : Icons.mic,
            Colors.white,
            onPressed: () => setState(() => _isMuted = !_isMuted),
          ),
          _buildEnhancedActionButton(
            _isFlashOn ? Icons.flash_on : Icons.flash_off,
            Colors.white,
            onPressed: () => setState(() => _isFlashOn = !_isFlashOn),
          ),
          _buildEnhancedActionButton(
            Icons.face,
            Colors.white,
            onPressed: () {
              // Open effects
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Effects panel opened')));
            },
          ),
          _buildEnhancedActionButton(
            Icons.more_vert,
            Colors.white,
            onPressed: _toggleLiveOptions,
          ),
        ],
      ),
    );
  }

  // Updated action button widget
  Widget _buildEnhancedActionButton(
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

// Helper classes for enhanced functionality
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onTap;

  const ChatBubble({required this.message, required this.onTap, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              message.isSystem
                  ? Colors.blue.withOpacity(0.3)
                  : message.isModerator
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                message.isModerator
                    ? Colors.purple.withOpacity(0.5)
                    : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                margin: EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: _getBadgeColor(message.badge!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  message.badge!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: message.username,
                      style: TextStyle(
                        color:
                            message.isSystem
                                ? Colors.blue[300]
                                : message.isModerator
                                ? Colors.purple[300]
                                : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(text: ': '),
                    TextSpan(
                      text: message.message,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'VIP':
        return Colors.purple;
      case 'Mod':
        return Colors.green;
      case 'Creator':
        return Colors.pink;
      case 'Top Fan':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class AnimatedViewerCount extends StatefulWidget {
  final int count;
  final Duration duration;

  const AnimatedViewerCount({
    required this.count,
    required this.duration,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedViewerCountState createState() => _AnimatedViewerCountState();
}

class _AnimatedViewerCountState extends State<AnimatedViewerCount>
    with SingleTickerProviderStateMixin {
  late int _displayCount;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _displayCount = widget.count;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(AnimatedViewerCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _controller.reset();
      _controller.forward();
      _displayCount = oldWidget.count;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCount =
        (_displayCount + (widget.count - _displayCount) * _animation.value)
            .toInt();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            _formatViewerCount(currentCount),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatViewerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

class PulseAnimation extends StatefulWidget {
  final Widget child;

  const PulseAnimation({required this.child, Key? key}) : super(key: key);

  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class FloatingHeart {
  final Color color;
  final IconData icon;
  final AnimationController controller;
  final double xPosition;

  FloatingHeart({
    required this.color,
    required this.icon,
    required this.controller,
    required this.xPosition,
  });
}

class ChatMessage {
  final String username;
  final String message;
  final String? badge;
  final bool isSystem;
  final bool isModerator;

  ChatMessage({
    required this.username,
    required this.message,
    this.badge,
    this.isSystem = false,
    this.isModerator = false,
  });
}
