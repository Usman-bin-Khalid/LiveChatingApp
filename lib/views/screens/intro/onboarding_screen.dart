import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _data = [
    OnboardingData(
      title: 'Real-time Messaging',
      description: 'Experience lightning fast communication with your friends and family across the globe.',
      image: 'assets/images/onboarding1.png',
    ),
    OnboardingData(
      title: 'Global Connectivity',
      description: 'Connect with anyone, anywhere. Our platform ensures you stay in touch no matter the distance.',
      image: 'assets/images/onboarding2.png',
    ),
    OnboardingData(
      title: 'Secure & Private',
      description: 'Your privacy is our priority. Enjoy end-to-end encrypted conversations with peace of mind.',
      image: 'assets/images/onboarding1.png', // Reusing for now or I can generate a 3rd one
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _data.length,
            itemBuilder: (context, index) {
              return OnboardingPage(data: _data[index]);
            },
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _data.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _data.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == _data.length - 1 ? 'Get Started' : 'Next',
                  ),
                ).animate().scale(),
              ],
            ),
          ),
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            data.image,
            height: 300,
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
          const SizedBox(height: 60),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}
