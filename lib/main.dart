import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';


// Global navigator key to handle navigation outside widget context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   debugPrint("clevertap _firebaseBackgroundMessageHandler Background");
//   CleverTapPlugin.createNotification(jsonEncode(message.data));
// }
// void _firebaseForegroundMessageHandler(RemoteMessage remoteMessage) {
//   debugPrint('clevertap _firebaseForegroundMessageHandler called');
//   CleverTapPlugin.createNotification(jsonEncode(remoteMessage.data));
// }


void main() async{
  // Ensures that widget binding is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  
  // Set CleverTap debug level (3 = verbose logs for debugging)
  CleverTapPlugin.setDebugLevel(3);
  
  // FirebaseMessaging.onMessage.listen(_firebaseForegroundMessageHandler);
  // FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);


  // Create an instance of CleverTapPlugin
  final CleverTapPlugin cleverTapPlugin = CleverTapPlugin();
  
  // Set up a handler for CleverTap push notification clicks
  cleverTapPlugin.setCleverTapPushNotificationClickedHandler(_onNotificationClicked);
  
  // Run the Flutter app
  runApp(const MyApp());
}

// Extension method for CleverTapPlugin to define a push notification click handler
extension on CleverTapPlugin {
  void setCleverTapPushNotificationClickedHandler(void Function(Map<String, dynamic> payload) onNotificationClicked) {}
}

// Callback function to handle push notification clicks
void _onNotificationClicked(Map<String, dynamic> payload) {
  debugPrint("Notification clicked: $payload");

  // Check if the notification contains a deep link key ("wzrk_dl")
  // If the deep link matches "myapp://second", navigate to the '/second' route
  if (payload.containsKey("wzrk_dl") && payload["wzrk_dl"] == "myapp://second") {
    navigatorKey.currentState?.pushNamed('/second');
  }
}



// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Global navigator key to handle navigation outside the widget context (useful for deep linking and push notifications)
      title: 'Navigation Basics', // Sets the title of the application
      home: const PermissionScreen(), // The initial screen that loads when the app starts
      routes: {
        '/userProfile': (context) => const UserProfileScreen(), // Route for navigating to the User Profile screen
        '/second': (context) => const NextPage(), // Route for navigating to the NextPage screen
      },
    );
  }
}


// PermissionScreen is a StatefulWidget responsible for handling permissions and CleverTap initialization
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  // Instance of CleverTapPlugin to interact with CleverTap services
  final CleverTapPlugin _cleverTapPlugin = CleverTapPlugin();
  
  @override
  void initState() {
    super.initState();
    // Initialize CleverTap setup and prompt the Push Primer
    _setupCleverTap();
  }
  
  // Sets up CleverTap configurations and handlers
  void _setupCleverTap() {
    // (_promptPushPrimer); // Prompts the user to enable notifications
    _cleverTapPlugin.setCleverTapDisplayUnitsLoadedHandler(_onDisplayUnitsLoaded); // Sets a handler for display units
    _initializeCleverTapInbox(); // Initializes the CleverTap Inbox feature
  }

  // Callback for when CleverTap display units are loaded
  void _onDisplayUnitsLoaded(List<dynamic>? displayUnits) {
    debugPrint("Display Units = $displayUnits");
  }

  // Requests permissions and navigates to the next screen
  void _requestPermissionsAndNavigate() async {
    try {
      // Request notification and location permissions
      await [
        Permission.notification,
        Permission.location,
      ].request();
      
      // Get current location if permission is granted
      _getCurrentLocation();
      
      // Always navigate to the next screen, regardless of permission status
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
      // Navigate to the next screen even if there's an error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
      }
    }
  }

  // Prompts the user with a push primer to enable notifications
  // void _promptPushPrimer() {
  //   var pushPrimerJSON = {
  //     'inAppType': 'alert',
  //     'titleText': 'Get Notified',
  //     'messageText': 'Enable Notification permission',
  //     'followDeviceOrientation': true,
  //     'positiveBtnText': 'Allow',
  //     'negativeBtnText': 'Cancel',
  //     'fallbackToSettings': true
  //   };
  //   CleverTapPlugin.promptPushPrimer(pushPrimerJSON);
  // }

  // Initializes CleverTap inbox and sets up message handlers
  void _initializeCleverTapInbox() {
    CleverTapPlugin.initializeInbox();
    _cleverTapPlugin.setCleverTapInboxDidInitializeHandler(_inboxDidInitialize);
    _cleverTapPlugin.setCleverTapInboxMessagesDidUpdateHandler(_inboxMessagesDidUpdate);
  }

  // Callback when CleverTap Inbox initializes
  void _inboxDidInitialize() {
    debugPrint("📥 CleverTap Inbox Initialized");
  }

  // Callback when CleverTap Inbox messages are updated
  void _inboxMessagesDidUpdate() {
    debugPrint("🔄 CleverTap Inbox Messages Updated");
  }

  // Retrieves the user's current location and sends it to CleverTap
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Get the current location with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // Set timeout to 5 seconds
      );
      
      // Send the obtained location to CleverTap
      CleverTapPlugin.setLocation(position.latitude, position.longitude);
      debugPrint("Location sent to CleverTap: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Requesting Permissions...", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _requestPermissionsAndNavigate, // Triggers permission request and navigation
              child: const Text(
                "Grant Permissions", 
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class ImageSlider extends StatefulWidget {
  final List<String> imageUrls;

  const ImageSlider({super.key, required this.imageUrls});

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    // Changed from 300ms to 3000ms (3 seconds) for better user experience
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentIndex < widget.imageUrls.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // Loop back to the first image
      }
      
      // Only animate if widget is still mounted and controller is attached
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500), // Slightly increased for smoother transition
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel(); // Cancel the timer when the widget is disposed
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
              // Don't restart timer on every manual page change
              // Just update the index and let the existing timer continue
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
          children: List.generate(
            widget.imageUrls.length,
            (index) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
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
  List<String> imageUrls = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  get token => null;

  @override
  void initState() {
    super.initState();
    _setupDisplayUnits();
  }
  
  void _setupDisplayUnits() async {
    _cleverTapPlugin.setCleverTapDisplayUnitsLoadedHandler(_onDisplayUnitsLoaded);
    try {
      var displayUnits = await CleverTapPlugin.getAllDisplayUnits();
      _onDisplayUnitsLoaded(displayUnits);
    } catch (e) {
      debugPrint("Error getting display units: $e");
    }
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
      
      debugPrint("Found ${imageUrls.length} images in display units");
    });
  }
  
  void _fetchNativeDisplay() async {
    CleverTapPlugin.recordEvent("Native Display", {});
    await Future.delayed(const Duration(seconds: 2));
    try {
      var displayUnits = await CleverTapPlugin.getAllDisplayUnits();
      _onDisplayUnitsLoaded(displayUnits);
    } catch (e) {
      debugPrint("Error fetching display units: $e");
    }
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
      'MSG-push':true,
      // 'MSG-push': true,
      
    };
  //   if (Platform.isAndroid) {
  //   CleverTapPlugin.setPushToken(token ?? '');
  //   CleverTapPlugin.profileSet({"MSG-push": true});
  //  }


    CleverTapPlugin.onUserLogin(profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User logged in successfully!")),
    );
    
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