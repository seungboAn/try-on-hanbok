import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';

class IndexScreen extends StatelessWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Reset app state when landing on index screen
    if (appState.hasUserImage || appState.hasSelectedHanbok || appState.hasResult) {
      // We only want to reset if returning to the index page after a session
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.reset();
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo/Icon or Decorative Image
              const Spacer(flex: 1),
              Image.asset(
                'assets/images/hanbok_logo.png',
                height: 120,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              // App Title
              const Text(
                'VirtualHanbok',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              // App Tagline
              const Text(
                'Experience the Beauty of Korean Traditional Clothing',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              
              // App Description
              const Text(
                'Select from our beautiful hanbok collection and try it on virtually with your photo.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              
              // Start Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/hanbok-selection');
                },
                child: const Text('Begin Your Hanbok Journey'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Already have an account? text
              TextButton(
                onPressed: () {
                  // This would normally go to a login screen
                  // For now, just show a dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Coming Soon'),
                      content: const Text('Account creation and login features will be available in a future update.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              
              const Spacer(flex: 1),
              
              // Footer/Version Info
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}