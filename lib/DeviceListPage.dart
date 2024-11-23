import 'dart:ui';
import 'package:cloud_sense_webapp/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AddDevice.dart';
import 'DeviceGraphPage.dart';
import 'HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class DataDisplayPage extends StatefulWidget {
  @override
  _DataDisplayPageState createState() => _DataDisplayPageState();
}

class _DataDisplayPageState extends State<DataDisplayPage> {
  bool _isLoading = true;
  Map<String, List<String>> _deviceCategories = {};
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  // Future<void> _loadEmail() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? email = prefs.getString('email');

  //   if (email != null) {
  //     setState(() {
  //       _email = email;
  //     });
  //     _fetchData();
  //   } else {
  //     // Handle case where email is not found, e.g., navigate to sign-in page
  //     Navigator.pushReplacementNamed(context, '/devicelist');
  //   }
  // }

  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email != null) {
      setState(() {
        _email = email;
      });
      _fetchData();
    } else {
      // Email not found, clear any authentication and redirect to login/signup page
      try {
        await Amplify.Auth
            .signOut(); // Optional: Sign out from Amplify if authenticated
      } catch (e) {
        print("Error signing out from Amplify: $e");
      }

      // Clear saved data in SharedPreferences
      await prefs.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SignInSignUpScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _fetchData() async {
    if (_email == null) return;

    final url =
        'https://ln8b1r7ld9.execute-api.us-east-1.amazonaws.com/default/Cloudsense_user_devices?email_id=$_email';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        setState(() {
          _deviceCategories = {
            for (var key in result.keys)
              if (key != 'device_id' && key != 'email_id')
                _mapCategory(key): List<String>.from(result[key] ?? [])
          };
        });
      }
    } catch (error) {
      // Handle errors appropriately
      print('Error fetching data: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _mapCategory(String key) {
    switch (key) {
      case 'CL':
      case 'BD':
        return 'Chlorine Sensors';
      case 'WD':
        return 'Weather Sensors';
      case 'SS':
        return 'Soil Sensors';
      case 'WQ':
        return 'Water Quality Sensors';
      case 'WS':
        return 'Water Sensors';
      // case 'LU': // LE -> CPS Lab Sensors
      // case 'TE': // TE -> CPS Lab Sensors
      // case 'AC': // ACC -> CPS Lab Sensors
      //   return 'CPS Lab Sensors'; // All grouped under CPS Lab Sensors
      case 'TE':
        return 'Temperature Sensors';
      case 'LU':
        return 'Lux Sensors';
      case 'AC':
        return 'Accelerometer Sensors';

      default:
        return key;
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email'); // Clear the saved email
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => HomePage()), // Navigate to HomePage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgroundd.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black
                    .withOpacity(0.4), // Optional overlay for readability
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  title: Text(
                    'Your Chosen Devices',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          MediaQuery.of(context).size.width < 800 ? 16 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await Amplify.Auth.signOut();
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.remove('email');

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        } catch (e) {
                          // Handle error during logout if necessary
                        }
                      }, // Logout function
                      icon: Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width < 800 ? 16 : 24,
                      ),
                      label: Text(
                        'Log out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              MediaQuery.of(context).size.width < 800 ? 12 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Add some space below the AppBar
                Center(
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Quote Text
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 70.0, left: 16.0, right: 16.0),
                              child: Text(
                                "Select a device to unlock insights into data.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize:
                                      MediaQuery.of(context).size.width < 800
                                          ? 30
                                          : 45,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    5), // Space between quote and device cards
                            _deviceCategories.isNotEmpty
                                ? _buildDeviceCards()
                                : _buildNoDevicesCard(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildDeviceCards() {
  //   List<Widget> cardList = _deviceCategories.keys.map((category) {
  //     return Container(
  //       width: 300,
  //       height: 300,
  //       margin: EdgeInsets.all(10),
  //       child: Card(
  //         color: _getCardColor(category),
  //         child: Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.center,
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               SizedBox(height: 30),
  //               Text(
  //                 category,
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.black,
  //                 ),
  //               ),
  //               SizedBox(height: 10),
  //               Expanded(
  //                 child: ListView.builder(
  //                   shrinkWrap: true,
  //                   itemCount: _deviceCategories[category]?.length ?? 0,
  //                   itemBuilder: (context, index) {
  //                     // Generate a sequential name like "Chlorine Sensor 1"
  //                     String sequentialName;
  //                     if (category.toLowerCase().contains("water quality")) {
  //                       sequentialName = 'Water Quality Sensor ${index + 1}';
  //                     } else {
  //                       sequentialName =
  //                           '${category.split(" ").first} Sensor ${index + 1}';
  //                     }
  //                     return Padding(
  //                       padding: const EdgeInsets.symmetric(vertical: 8.0),
  //                       child: ElevatedButton(
  //                         style: ElevatedButton.styleFrom(
  //                           foregroundColor: Colors.white,
  //                           backgroundColor: Colors.black, // Text color
  //                           padding: EdgeInsets.symmetric(
  //                               horizontal: 20, vertical: 10),
  //                         ),
  //                         onPressed: () {
  //                           Navigator.push(
  //                             context,
  //                             MaterialPageRoute(
  //                               builder: (context) => DeviceGraphPage(
  //                                 deviceName:
  //                                     _deviceCategories[category]![index],
  //                                 sequentialName: sequentialName,
  //                                 backgroundImagePath: 'assets/backgroundd.jpg',
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                         // onPressed: () {

  //                         child: Text(
  //                           sequentialName,
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                           ),
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }).toList();

  //   // Add the "Add Devices" button as a card
  //   cardList.add(
  //     Container(
  //       width: 300,
  //       height: 300,
  //       margin: EdgeInsets.all(10),
  //       child: Card(
  //         color: const Color.fromARGB(255, 167, 158, 172),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             // Plus sign above the button
  //             Padding(
  //               padding: const EdgeInsets.all(16.0),
  //               child: Icon(
  //                 Icons.add,
  //                 size: 80,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             // Add Devices button
  //             ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  //                 backgroundColor: Colors.black,
  //               ),
  //               onPressed: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => QRScannerPage(
  //                       devices: _deviceCategories,
  //                     ),
  //                   ),
  //                 );
  //               },
  //               child: Text(
  //                 'Add Devices',
  //                 style: TextStyle(
  //                     color: const Color.fromARGB(255, 245, 241, 240)),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );

  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: cardList,
  //     ),
  //   );
  // }

  Widget _buildDeviceCards() {
    List<Widget> cardList = _deviceCategories.keys.map((category) {
      // Grouping CPS Lab sensors
      // if (category == 'CPS Lab Sensors') {
      //   return _buildCPSLabCard();
      // }

      return Container(
        width: 300,
        height: 300,
        margin: EdgeInsets.all(10),
        child: Card(
          color: _getCardColor(category),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _deviceCategories[category]?.length ?? 0,
                    itemBuilder: (context, index) {
                      String sequentialName =
                          '${category.split(" ").first} Sensor ${index + 1}';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black, // Text color
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeviceGraphPage(
                                  deviceName:
                                      _deviceCategories[category]![index],
                                  sequentialName: sequentialName,
                                  backgroundImagePath: 'assets/backgroundd.jpg',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            sequentialName,
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    // Add the "Add Devices" button as a card
    cardList.add(
      Container(
        width: 300,
        height: 300,
        margin: EdgeInsets.all(10),
        child: Card(
          color: const Color.fromARGB(255, 167, 158, 172),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  Icons.add,
                  size: 80,
                  color: Colors.black,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRScannerPage(
                        devices: _deviceCategories,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Add Device',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cardList,
      ),
    );
  }

//   Widget _buildCPSLabCard() {
//     // Categorize CPS Lab sensors by their prefixes (LU, TE, AC)
//     List<String> cpsLabSensors = _deviceCategories['CPS Lab Sensors'] ?? [];
//     Map<String, List<String>> groupedSensors = {
//       'LU': [],
//       'TE': [],
//       'AC': [],
//     };

//     // Group sensors based on their prefixes
//     for (String sensor in cpsLabSensors) {
//       if (sensor.startsWith('LU')) {
//         groupedSensors['LU']?.add(sensor);
//       } else if (sensor.startsWith('TE')) {
//         groupedSensors['TE']?.add(sensor);
//       } else if (sensor.startsWith('AC')) {
//         groupedSensors['AC']?.add(sensor);
//       }
//     }

//     return Container(
//       width: 300,
//       height: 300,
//       margin: EdgeInsets.all(10),
//       child: Card(
//         color: _getCardColor('CPS Lab Sensors'),
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SizedBox(height: 10),
//               Text(
//                 'CPS Lab Sensors',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Expanded(
//                 child: ListView(
//                   shrinkWrap: true,
//                   children: [
//                     // Group LU Sensors
//                     if (groupedSensors['LU']?.isNotEmpty ?? false)
//                       _buildSensorGroup('LU', groupedSensors['LU']!),

//                     // Group TE Sensors
//                     if (groupedSensors['TE']?.isNotEmpty ?? false)
//                       _buildSensorGroup('TE', groupedSensors['TE']!),

//                     // Group AC Sensors
//                     if (groupedSensors['AC']?.isNotEmpty ?? false)
//                       _buildSensorGroup('AC', groupedSensors['AC']!),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

// // Helper function to build a sensor group (LU, TE, AC)
//   Widget _buildSensorGroup(String sensorType, List<String> sensors) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Subheading for sensor type (LU, TE, AC)
//           Text(
//             '$sensorType Sensors',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.black54,
//             ),
//           ),
//           SizedBox(height: 10),
//           // List of sensors for the group
//           ...sensors.asMap().entries.map((entry) {
//             int index = entry.key;
//             String sensorName = entry.value;

//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.black, // Button color
//                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => DeviceGraphPage(
//                         deviceName: sensorName,
//                         sequentialName: '$sensorType Sensor ${index + 1}',
//                         backgroundImagePath: 'assets/backgroundd.jpg',
//                       ),
//                     ),
//                   );
//                 },
//                 child: Text(
//                   '$sensorType Sensor ${index + 1}',
//                   style: TextStyle(
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }

  Widget _buildNoDevicesCard() {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        margin: EdgeInsets.all(10),
        child: Card(
          color: const Color.fromARGB(255, 167, 158, 172),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Message Text
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No devices found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    color: const Color.fromARGB(255, 235, 28, 28),
                  ),
                ),
              ),
              // Plus sign above the button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  Icons.add,
                  size: 80,
                  color: Colors.black,
                ),
              ),
              // Add Devices button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QRScannerPage(devices: _deviceCategories),
                    ),
                  );
                },
                child: Text(
                  'Add Devices',
                  style: TextStyle(
                      color: const Color.fromARGB(255, 245, 241, 240)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(String category) {
    switch (category) {
      case 'Chlorine Sensors':
        return const Color.fromARGB(255, 167, 158, 172);
      case 'Weather Sensors':
        return const Color.fromARGB(255, 167, 158, 172);
      case 'Soil Sensors': // Add color for Soil Sensors
        return const Color.fromARGB(255, 167, 158, 172);
      case 'Water Quality Sensors': // Add color for Water Sensors
        return const Color.fromARGB(255, 167, 158, 172);
      case 'Water Sensors': // Add color for Water Sensors
        return const Color.fromARGB(255, 167, 158, 172);
      case 'DO Sensors': // Add color for Water Sensors
        return const Color.fromARGB(255, 167, 158, 172);
      case 'Temperature Sensors':
        return const Color.fromARGB(
            255, 167, 158, 172); // Custom color for CPS Lab
      case 'Lux Sensors':
        return const Color.fromARGB(
            255, 167, 158, 172); // Custom color for CPS Lab
      case 'Accelerometer Sensors':
        return const Color.fromARGB(
            255, 167, 158, 172); // Custom color for CPS Lab
      default:
        return const Color.fromARGB(255, 167, 158, 172);
    }
  }
}
