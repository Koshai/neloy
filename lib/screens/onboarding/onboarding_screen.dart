import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to PropertyPro',
      description: 'The easiest way to manage your rental properties, track income and expenses, and stay organized.',
      imagePath: 'assets/images/onboarding_welcome.png',
      backgroundColor: Colors.blue[50]!,
      textColor: Colors.blue[900]!,
    ),
    OnboardingPage(
      title: 'Track Your Properties',
      description: 'Store all your property details in one place. Add photos, documents, and manage tenant information.',
      imagePath: 'assets/images/onboarding_properties.png',
      backgroundColor: Colors.green[50]!,
      textColor: Colors.green[900]!,
    ),
    OnboardingPage(
      title: 'Manage Your Finances',
      description: 'Track rent payments, expenses, and see detailed financial reports. Know exactly how profitable each property is.',
      imagePath: 'assets/images/onboarding_finances.png',
      backgroundColor: Colors.purple[50]!,
      textColor: Colors.purple[900]!,
    ),
    OnboardingPage(
      title: 'Stay Organized',
      description: 'Calendar integration helps you track important dates. Store documents digitally for easy access anytime.',
      imagePath: 'assets/images/onboarding_organized.png',
      backgroundColor: Colors.orange[50]!,
      textColor: Colors.orange[900]!,
    ),
    OnboardingPage(
      title: 'Start For Free',
      description: 'Get started with one property and up to 5 tenants at no cost. Upgrade anytime to manage your entire portfolio.',
      imagePath: 'assets/images/onboarding_free.png',
      backgroundColor: Colors.amber[50]!,
      textColor: Colors.amber[900]!,
      useFreemiumDescription: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
        _isLastPage = _currentPage == _pages.length - 1;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return OnboardingPageWidget(page: page);
            },
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  if (!_isLastPage)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _pages.length - 1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                      child: Text('Skip'),
                    )
                  else
                    SizedBox(width: 80),
                  
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: _pages[_currentPage].textColor,
                      dotColor: _pages[_currentPage].textColor.withOpacity(0.3),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                    ),
                  ),
                  
                  // Next/Get Started button
                  _isLastPage
                      ? ElevatedButton(
                          onPressed: _onGetStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].textColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text('Get Started Free'),
                        )
                      : IconButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          },
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            color: _pages[_currentPage].textColor,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final Color textColor;
  final bool useFreemiumDescription;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    required this.textColor,
    this.useFreemiumDescription = false,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: page.backgroundColor,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.only(top: 80),
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  page.title,
                  style: TextStyle(
                    color: page.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Text(
                  page.description,
                  style: TextStyle(
                    color: page.textColor.withOpacity(0.8),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (page.useFreemiumDescription) ...[
                  SizedBox(height: 32),
                  _buildFreemiumComparison(context, page.textColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFreemiumComparison(BuildContext context, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Free Plan Includes:',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 12),
          _buildFeatureRow('1 Property', Icons.home),
          _buildFeatureRow('5 Tenants', Icons.people),
          _buildFeatureRow('5 Documents', Icons.file_copy),
          _buildFeatureRow('Core Financial Tracking', Icons.attach_money),
          SizedBox(height: 16),
          Text(
            'Upgrade anytime for unlimited properties',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureRow(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: page.textColor),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: page.textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}