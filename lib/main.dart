import 'package:flutter/material.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CleverTapPlugin.setDebugLevel(3);
  runApp(const MyApp());
}

// Push Primer configuration using Half-Interstitial template
var pushPrimerConfig = {
  'inAppType': 'half-interstitial',
  'titleText': 'Get Notified',
  'messageText': 'Please enable notifications on your device to use Push Notifications.',
  'followDeviceOrientation': false,
  'positiveBtnText': 'Allow',
  'negativeBtnText': 'Cancel',
  'fallbackToSettings': true,
  'backgroundColor': '#FFFFFF',
  'btnBorderColor': '#000000',
  'titleTextColor': '#000000',
  'messageTextColor': '#000000',
  'btnTextColor': '#000000',
  'btnBackgroundColor': '#FFFFFF',
  'btnBorderRadius': '4',
  'imageUrl': 'https://icons.iconarchive.com/icons/treetog/junior/64/camera-icon.png'
};

var pushPrimerConfigAlert = {
  'inAppType': 'alert',
  'titleText': 'Get Notified',
  'messageText': 'Enable Notification permission',
  'followDeviceOrientation': true,
  'positiveBtnText': 'Allow',
  'negativeBtnText': 'Cancel',
  'fallbackToSettings': true
};


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Basics',
      home: const PermissionScreen(), // Starting screen with permission request
    );
  }
}

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
    _requestPermissions();
    _initializeCleverTapInbox();
    _getCurrentLocation();
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
          ],
        ),
      ),
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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
        child: Column(
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
          ],
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
          onPressed: () {
            Navigator.pop(context); // This goes back to the previous screen
          },
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
