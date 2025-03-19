import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

// Global navigator key to handle navigation outside widget context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();    // Ensures Flutter bindings are initialized before running the app
  CleverTapPlugin.setDebugLevel(3); // Sets CleverTap debug level for logging
  // Initialize CleverTap instance
  final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin();
  // Register notification handler on instance
  _cleverTapPlugin.setCleverTapPushNotificationClickedHandler(_onNotificationClicked);
  runApp(const MyApp());
}

extension on CleverTapPlugin {
  void setCleverTapPushNotificationClickedHandler(void Function(Map<String, dynamic> payload) onNotificationClicked) {}
}

// Handle notification clicks
void _onNotificationClicked(Map<String, dynamic> payload) {
  debugPrint("Notification clicked: $payload");

  if (payload.containsKey("wzrk_dl") && payload["wzrk_dl"] == "myapp://second") {
    navigatorKey.currentState?.pushNamed('/second');
  }
}

// Main app with navigatorKey and routes
class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Ensuring only one navigation tree
      title: 'Navigation Basics',
      home: const PermissionScreen(), // Starting screen
      routes: {
        '/userProfile': (context) => const UserProfileScreen(),
        '/second': (context) => const NextPage(),
      },
    );
  }
}

//Handles requesting permissions and location services.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin();
  
  @override
  void initState() {
    super.initState();
    // Remove async from initState
    _setupInitialState();
  }
  
  // Created a separate method to handle async operations
  void _setupInitialState() async {
    _promptPushPrimer();
    setlistener();
    _requestPermissions();
    _initializeCleverTapInbox();
    _getCurrentLocation();
    
    // Set the handler using instance (not static)
    _cleverTapPlugin.setCleverTapDisplayUnitsLoadedHandler(onDisplayUnitsLoaded);
    var displayUnits = await CleverTapPlugin.getAllDisplayUnits();
    onDisplayUnitsLoaded(displayUnits);
  }

  void setlistener() {
    // Using the consistent handler name on instance
    _cleverTapPlugin.setCleverTapDisplayUnitsLoadedHandler(onDisplayUnitsLoaded);
    debugPrint("Listener set");
  }
  
  void onDisplayUnitsLoaded(List<dynamic>? displayUnits) {
    debugPrint("Display Units = $displayUnits");
    // No need for duplicate handlers
  }
  
  void _fetchNativeDisplay() async {
    CleverTapPlugin.recordEvent("Native Display", {});
    await Future.delayed(const Duration(seconds: 2));
    var displayUnits = await CleverTapPlugin.getAllDisplayUnits();
    onDisplayUnitsLoaded(displayUnits);
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
      Permission.location,
    ].request();

    if (statuses[Permission.notification]?.isGranted ?? false) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
      }
    }
  }

   void _promptPushPrimer() {
    var pushPrimerJSON = {
  'inAppType': 'alert',
  'titleText': 'Get Notified',
  'messageText': 'Enable Notification permission',
  'followDeviceOrientation': true,
  'positiveBtnText': 'Allow',
  'negativeBtnText': 'Cancel',
  'fallbackToSettings': true

};
    CleverTapPlugin.promptPushPrimer(pushPrimerJSON);
}


  void _initializeCleverTapInbox() {
    CleverTapPlugin.initializeInbox();
    _cleverTapPlugin.setCleverTapInboxDidInitializeHandler(inboxDidInitialize);
    _cleverTapPlugin.setCleverTapInboxMessagesDidUpdateHandler(inboxMessagesDidUpdate);
  }

  void inboxDidInitialize() {
    setState(() {
      print("📥 CleverTap Inbox Initialized");
    });
  }

  void inboxMessagesDidUpdate() {
    setState(() {
      print("🔄 CleverTap Inbox Messages Updated");
    });
  }

  //get the current location of the user and send it to CleverTap.
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double latitude = position.latitude;
    double longitude = position.longitude;

    print("Latitude: $latitude, Longitude: $longitude"); // Debugging line

    // Send location data to CleverTap
    CleverTapPlugin.setLocation(latitude, longitude);
    print("Location sent to CleverTap"); // Debugging line
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Requesting Permissions..."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text("Grant Permissions"),
            ),
            const SizedBox(height: 10),
            // Added button to fetch native display
            ElevatedButton(
              onPressed: _fetchNativeDisplay,
              child: const Text("Fetch Native Display"),
            ),
          ],
        ),
      ),
    );
  }
}

// Image slider widget for displaying multiple images with a slider
class ImageSlider extends StatefulWidget {
  final List<String> imageUrls;

  const ImageSlider({Key? key, required this.imageUrls}) : super(key: key);

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const Center(child: Text("No images available"));
    }

    return Column(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text("Error loading image"),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentIndex > 0
                  ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),
            Text(
              "${_currentIndex + 1} / ${widget.imageUrls.length}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentIndex < widget.imageUrls.length - 1
                  ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),
          ],
        ),
        // Add indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.imageUrls.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin();
  // Move imageUrls inside this class as a state variable
  List<String> imageUrls = [];

  //Controllers to take input from the user
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupDisplayUnits();
  }
  
  void _setupDisplayUnits() async {
    // Set up the display units handler on instance
    _cleverTapPlugin.setCleverTapDisplayUnitsLoadedHandler(_onDisplayUnitsLoaded);
    var displayUnits = await CleverTapPlugin.getAllDisplayUnits();
    _onDisplayUnitsLoaded(displayUnits);
  }

  void _onDisplayUnitsLoaded(List<dynamic>? displayUnits) {
    if (displayUnits == null || displayUnits.isEmpty) return;
    
    setState(() {
      imageUrls = displayUnits
          .where((unit) => unit["content"] is List)
          .expand((unit) => unit["content"])
          .map((content) => content["media"]?["url"])
          .whereType<String>()
          .toList();
      
      debugPrint("Image URLs updated: ${imageUrls.length} images found");
      for (var i = 0; i < imageUrls.length; i++) {
        debugPrint("Image $i: ${imageUrls[i]}");
      }
    });
  }
  
  void _fetchNativeDisplay() async {
    CleverTapPlugin.recordEvent("Native Display", {});
    await Future.delayed(const Duration(seconds: 2));
    var displayUnits = await CleverTapPlugin.getAllDisplayUnits();
    _onDisplayUnitsLoaded(displayUnits);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void onUserLogin() {
    var profile = {
      'Name': _nameController.text,
      'Identity': _identityController.text,
      'Email': _emailController.text,
      'Phone': _phoneController.text,
      'stuff': ["bags", "shoes"],
    };
    CleverTapPlugin.onUserLogin(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User logged in successfully!")),
    );
    
    // Fetch native display after login
    _fetchNativeDisplay();
  }

  void updateUserProfile() {
    var profile = {
      'Name': _nameController.text,
      'Identity': _identityController.text,
      'Email': _emailController.text,
      'Phone': _phoneController.text,
      'DOB': CleverTapPlugin.getCleverTapDate(DateTime.parse('2012-04-22')),
      'props': 'property1',
      'stuff': ["bags", "shoes"],
    };
    CleverTapPlugin.profileSet(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
    
    // Fetch native display after profile update
    _fetchNativeDisplay();
  }

  void openInbox() {
    CleverTapPlugin.initializeInbox();
    Future.delayed(const Duration(seconds: 1), () {
      var styleConfig = {
        'noMessageTextColor': '#ff6600',
        'noMessageText': 'No messages yet!',
        'navBarTitle': 'App Inbox Message'
      };
      CleverTapPlugin.showInbox(styleConfig);
    });
  }

  void navigateToNextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NextPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CleverTap User Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: _identityController, decoration: const InputDecoration(labelText: "Identity")),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onUserLogin, child: const Text("On User Login")),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: updateUserProfile, child: const Text("Update Profile")),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: openInbox, child: const Text("Open App Inbox")),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: navigateToNextPage, child: const Text("Go to Next Page")),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _fetchNativeDisplay, child: const Text("Refresh Native Display")),
              const SizedBox(height: 20),
              Text(
                "Native Display Images (${imageUrls.length})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (imageUrls.isNotEmpty)
                ImageSlider(imageUrls: imageUrls),
              if (imageUrls.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "No display units available. Try refreshing or logging in.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Next Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          child: const Text('Go Home'),
        ),
      ),
    );
  }
}