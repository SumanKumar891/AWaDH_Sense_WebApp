import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Cloud Sense',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode); // Save the preference
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode =
        prefs.getBool('isDarkMode') ?? false; // Default to light theme
    notifyListeners(); // Notify listeners after loading the theme
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color _aboutUsColor = const Color.fromARGB(255, 235, 232, 232);
  Color _loginTestColor = const Color.fromARGB(255, 235, 232, 232);
  Color _accountinfoColor = const Color.fromARGB(255, 235, 232, 232);
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 800;
      return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              isMobile ? SizedBox(width: 10) : SizedBox(width: 80),
              Icon(Icons.cloud, color: Colors.white, size: isMobile ? 24 : 32),
              SizedBox(width: isMobile ? 10 : 20),
              Text(
                'Cloud Sense',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 20 : 32,
                ),
              ),
              Spacer(),
              if (isMobile)
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              if (!isMobile) ...[
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
                SizedBox(width: 20),
                _buildNavButton('ABOUT US', _aboutUsColor, () {
                  Navigator.pushNamed(context, '/about-us');
                }),
                SizedBox(width: 20),
                _buildNavButton('LOGIN/SIGNUP', _loginTestColor, () {
                  Navigator.pushNamed(context, '/login');
                }),
                SizedBox(width: 20),
                _buildNavButton('ACCOUNT INFO', _accountinfoColor, () {
                  Navigator.pushNamed(context, '/accountinfo');
                }),
              ],
            ],
          ),
        ),
        endDrawer: isMobile
            ? Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                      ),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.info),
                      title: Text('ABOUT US'),
                      onTap: () {
                        Navigator.pushNamed(context, '/about-us');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.login),
                      title: Text('LOGIN/SIGNUP'),
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.login),
                      title: Text('ACCOUNT INFO'),
                      onTap: () {
                        Navigator.pushNamed(context, '/accountinfo');
                      },
                    ),
                  ],
                ),
              )
            : null,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.asset(
                    'assets/soil.jpg',
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width < 800 ? 400 : 550,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width < 800 ? 400 : 550,
                    color: Colors.black.withOpacity(0.5),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width < 800 ? 20 : 100,
                      top: MediaQuery.of(context).size.width < 800 ? 60 : 120,
                      right:
                          MediaQuery.of(context).size.width < 1000 ? 60 : 400,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Cloud Sense',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: MediaQuery.of(context).size.width < 800
                                ? 40
                                : 65,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: Text(
                            "At Cloud Sense, we're dedicated to providing you with real-time data to help you make informed decisions about your surroundings.Our app uses advanced technology to ensure the data is accurate and timely, giving you the insights you need when it matters most. ",
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 800
                                  ? 16
                                  : 22,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50),
// "What We Offer" Section
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 233, 229, 230),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 194, 196, 194),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset:
                                    Offset(0, 4), // changes position of shadow
                              ),
                              BoxShadow(
                                color: const Color.fromARGB(255, 194, 196, 194),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, -4), // shadow at the top
                              ),
                              BoxShadow(
                                color: const Color.fromARGB(255, 194, 196, 194)
                                    .withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(-4, 0), // shadow at the left
                              ),
                              BoxShadow(
                                color: const Color.fromARGB(255, 194, 196, 194),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(4, 0), // shadow at the right
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(60.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'What We Offer?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Explore the sensors and dive into the live data they capture. With just a tap, you can access detailed insights for each sensor, keeping you informed.\n\nMonitor conditions to ensure a healthy and safe space, detect potential issues, and stay alert for any irregularities. Track various factors to help you plan effectively and contribute to optimizing your usage. Fine-tune your surroundings to prevent potential problems and adjust settings for comfort and efficiency. With all the essential insights at your fingertips, you can create a more comfortable and sustainable living space.',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 800
                                            ? 14
                                            : 20,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: 50),
              // "Our Mission" Section
              Stack(
                children: [
                  Image.asset(
                    'assets/weather.png',
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width < 800 ? 400 : 500,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width < 800 ? 400 : 500,
                    color: Colors.black.withOpacity(0.5),
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width < 800 ? 20.0 : 80.0,
                      MediaQuery.of(context).size.width < 800 ? 40.0 : 85.0,
                      MediaQuery.of(context).size.width < 800 ? 20.0 : 90.0,
                      50.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Our Mission',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 800
                                ? 30
                                : 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'At Cloud Sense, we aim to revolutionize the way you interact with your surroundings by offering intuitive and seamless monitoring solutions. Our innovative app provides instant access to essential data, giving you the tools to anticipate and respond to changes. With Cloud Sense, you can trust that you’re equipped with the knowledge needed to maintain a safe, healthy, and efficient lifestyle.',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 800
                                ? 18
                                : 24,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0),

              Container(
                color: const Color.fromARGB(255, 10, 10, 10),
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Address : IIT Ropar TIF (AWaDH), 214 / M. Visvesvaraya Block, Indian Institute of Technology Ropar, Rupnagar - 140001, Punjab ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 18),
                    GestureDetector(
                      onTap: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: '01881-232601',
                        );

                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        } else {
                          throw 'Could not launch $launchUri';
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          children: [
                            TextSpan(text: 'Phone : '),
                            TextSpan(
                              text: '01881 - 232601',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    GestureDetector(
                      onTap: () async {
                        final Uri params = Uri(
                          scheme: 'mailto',
                          path: 'contact.awadh@iitrpr.ac.in',
                        );

                        // Check if the email URL can be launched
                        if (await canLaunchUrl(params)) {
                          await launchUrl(params);
                        } else {
                          throw ('Could not launch $params');
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          children: [
                            TextSpan(text: 'Email : '),
                            TextSpan(
                              text: 'contact.awadh@iitrpr.ac.in',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
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
        ),
      );
    });
  }

  Widget _buildNavButton(String text, Color color, VoidCallback onPressed) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        if (text == 'ABOUT US') _aboutUsColor = Colors.blue;
        if (text == 'LOGIN/SIGNUP') _loginTestColor = Colors.blue;
        if (text == 'ACCOUNT INFO') _accountinfoColor = Colors.blue;
        // if (text == 'CONTACT US') _contactUsColor = Colors.blue;
      }),
      onExit: (_) => setState(() {
        if (text == 'ABOUT US')
          _aboutUsColor = const Color.fromARGB(255, 235, 232, 232);
        if (text == 'LOGIN/SIGNUP')
          _loginTestColor = const Color.fromARGB(255, 235, 232, 232);
        if (text == 'ACCOUNT INFO')
          _accountinfoColor = const Color.fromARGB(255, 235, 232, 232);
        // if (text == 'CONTACT US')
        //   _contactUsColor = const Color.fromARGB(255, 235, 232, 232);
      }),
      child: TextButton(
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: color)),
      ),
    );
  }
}
