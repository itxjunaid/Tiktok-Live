import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:live_tiktok/tiktok_stream_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Request camera and microphone permissions
  static Future<bool> requestCameraAccess() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      final controller = CameraController(cameras.first, ResolutionPreset.low);
      await controller.initialize();
      await controller.dispose();
      return true;
    } catch (e) {
      print('Camera permission issue: $e');
      return false;
    }
  }

  // Check if permissions are already granted
  static Future<bool> hasCameraPermissions() async {
    bool camera = await Permission.camera.isGranted;
    bool microphone = await Permission.microphone.isGranted;

    return camera && microphone;
  }

  // Open app settings if permissions are permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

class CameraService {
  CameraController? controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;

  // Initialize available cameras
  Future<void> initCameras() async {
    cameras = await availableCameras();
  }

  // Initialize camera controller
  Future<bool> initCameraController() async {
    if (cameras == null || cameras!.isEmpty) {
      await initCameras();
    }

    if (cameras == null || cameras!.isEmpty) {
      return false;
    }

    controller = CameraController(
      cameras![selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller!.initialize();
      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  // Switch between front and back cameras
  Future<void> flipCamera() async {
    if (cameras == null || cameras!.length <= 1) return;

    selectedCameraIndex = selectedCameraIndex == 0 ? 1 : 0;

    await controller?.dispose();
    await initCameraController();
  }

  // Dispose of camera controller when not in use
  Future<void> dispose() async {
    await controller?.dispose();
    controller = null;
  }
}

class TikTokLiveScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const TikTokLiveScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<TikTokLiveScreen> createState() => _TikTokLiveScreenState();
}

class _TikTokLiveScreenState extends State<TikTokLiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late CameraService _cameraService;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  int _selectedLiveOption =
      1; // 0: Voice chat, 1: Device camera, 2: Mobile gaming
  String _titleText = 'Minecraft';
  bool _isEditingTitle = false;
  final TextEditingController _titleController = TextEditingController();
  int _currentPageIndex = 2; // Start with Live tab selected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _pageController = PageController(initialPage: 2);
    _titleController.text = _titleText;

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPageIndex = _tabController.index;
        });
      }
    });

    _cameraService = CameraService();
    _checkPermissionsAndInitCamera();
  }

  Future<void> _checkPermissionsAndInitCamera() async {
    // Check if camera permissions are granted
    bool hasPermissions = await PermissionService.hasCameraPermissions();

    if (!hasPermissions) {
      // Request permissions if not granted
      hasPermissions = await PermissionService.requestCameraAccess();

      if (!hasPermissions) {
        setState(() {
          _isPermissionGranted = false;
        });

        // Show permission denied dialog
        _showPermissionDeniedDialog();
        return;
      }
    }

    setState(() {
      _isPermissionGranted = true;
    });

    // Initialize camera after permissions are granted
    await _cameraService.initCameras();
    bool initialized = await _cameraService.initCameraController();

    if (initialized) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Camera Permission Required'),
            content: Text(
              'This app needs camera access to stream live video. Please grant camera permissions in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text('OPEN SETTINGS'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _tabController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for different tabs
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
                _tabController.animateTo(index);
              });
            },
            children: [
              // POST PAGE
              _buildPostPage(),

              // TEMPLATES PAGE
              _buildTemplatesPage(),

              // LIVE PAGE
              _buildLivePage(),
            ],
          ),

          // Bottom Tab Bar always visible
          Positioned(bottom: 0, left: 0, right: 0, child: _buildTabBar()),
        ],
      ),
    );
  }

  Widget _buildPostPage() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'POST',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesPage() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'TEMPLATES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLivePage() {
    return Stack(
      children: [
        // Camera Preview or placeholder
        _buildCameraPreview(),

        // Main content overlay
        SafeArea(
          child: Column(
            children: [
              // Top options with profile and live details
              _buildTopSection(),

              // Spacer to push content to bottom
              Expanded(child: Container()),

              // Live controls grid
              _buildLiveControlsGrid(),

              // Bottom options with Go Live button
              _buildBottomSection(),

              // Extra space for tab bar
              SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitialized &&
        _isPermissionGranted &&
        _cameraService.controller != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: CameraPreview(_cameraService.controller!),
      );
    } else if (!_isPermissionGranted) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Camera permission is required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _checkPermissionsAndInitCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Top bar with close button and creator profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {},
                ),
              ),

              // Creator profile
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=80&q=80',
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '@creator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title text field section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade600, width: 0.5),
            ),
            child: Row(
              children: [
                _isEditingTitle
                    ? Expanded(
                      child: TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter title',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            _titleText =
                                value.isNotEmpty ? value : 'Live Stream';
                            _isEditingTitle = false;
                          });
                        },
                      ),
                    )
                    : Expanded(
                      child: Text(
                        _titleText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingTitle = !_isEditingTitle;
                      if (_isEditingTitle) {
                        _titleController.text = _titleText;
                        // Focus on the text field
                        FocusScope.of(context).nextFocus();
                      } else {
                        _titleText =
                            _titleController.text.isNotEmpty
                                ? _titleController.text
                                : 'Live Stream';
                      }
                    });
                  },
                  child: Icon(
                    _isEditingTitle ? Icons.check : Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Add topic field with modern design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade600, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.star, color: Colors.amber, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Add topic',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: 14,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Add a LIVE goal field with modern design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade600, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: Colors.purple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Add a LIVE goal',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveControlsGrid() {
    // Enhanced control options with more TikTok-like features
    final List<Map<String, dynamic>> controls = [
      {'icon': Icons.flip_camera_ios, 'label': 'Flip'},
      {'icon': Icons.brush, 'label': 'Effects'},
      {'icon': Icons.settings, 'label': 'Settings'},
      {'icon': Icons.mood, 'label': 'Filter'},
      {'icon': Icons.auto_awesome, 'label': 'Beauty'},
      {'icon': Icons.people, 'label': 'Guests'},
      {'icon': Icons.share, 'label': 'Share'},
      {'icon': Icons.music_note, 'label': 'Music'},
      {'icon': Icons.filter, 'label': 'Levels'},
      {'icon': Icons.shield, 'label': 'Shield'},
      {'icon': Icons.card_giftcard, 'label': 'Gifts'},
      {'icon': Icons.stacked_line_chart, 'label': 'Stats'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 0,
          crossAxisSpacing: 7,
          childAspectRatio: 0.9,
        ),
        itemCount: controls.length,
        itemBuilder: (context, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  if (controls[index]['label'] == 'Flip') {
                    await _cameraService.flipCamera();
                    setState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade700, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    controls[index]['icon'],
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(height: 3),
              Text(
                controls[index]['label'],
                style: TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Live Options (Voice chat, Device camera, Mobile gaming)

        // Go Live button - modern design
        Container(
          margin: const EdgeInsets.symmetric(vertical: 0),
          width: MediaQuery.of(context).size.width * 0.8,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _showCountdownDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.red.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.live_tv, size: 22),
                SizedBox(width: 8),
                Text(
                  'Go LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: Colors.indigo.withOpacity(0),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          height: 80, // Give it a fixed height
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildLiveOptionButton(0, Icons.call, 'Voice chat'),
              SizedBox(width: 40),
              _buildLiveOptionButton(1, Icons.camera_alt, 'Device camera'),
              SizedBox(width: 40),
              _buildLiveOptionButton(2, Icons.smartphone, 'Mobile gaming'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveOptionButton(int index, IconData icon, String label) {
    bool isSelected = _selectedLiveOption == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLiveOption = index;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade400,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey.shade900, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.pink, width: 3.0)),
        ),
        labelColor: Colors.red,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: [Tab(text: 'POST'), Tab(text: 'TEMPLATES'), Tab(text: 'LIVE')],
      ),
    );
  }

  void _showCountdownDialog() {
    int countdown = 3;
    late Timer timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Start timer only once
            if (countdown == 3) {
              timer = Timer.periodic(Duration(seconds: 1), (t) async {
                if (countdown == 1) {
                  t.cancel();
                  Navigator.of(context).pop(); // close dialog
                  final cameras = await availableCameras();
                  if (cameras.isEmpty) {
                    // Handle case when no cameras are available
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TikTokLiveStreamScreen(
                            cameras: cameras,
                            liveTitle: 'My Live Stream',
                          ),
                    ),
                  );
                } else {
                  setState(() {
                    countdown--;
                  });
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(40),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 600),
                  transitionBuilder:
                      (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                  child: Text(
                    '$countdown',
                    key: ValueKey(countdown),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 20, color: Colors.redAccent),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Ensure timer is cancelled if dialog is dismissed early
      if (timer.isActive) timer.cancel();
    });
  }
}
