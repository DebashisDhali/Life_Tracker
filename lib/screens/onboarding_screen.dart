import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Balance Your Life",
      description: "Achieve harmony across Body, Mind, Money, Skill, Relationship, and Dharma.",
      icon: Icons.track_changes_rounded, // Placeholder, we will use custom painter/widget
      color: AppColors.sectionBody,
    ),
    OnboardingPage(
      title: "Build Consistent Habits",
      description: "Create streaks, track daily growth, and celebrate small wins every day.",
      icon: Icons.local_fire_department_rounded,
      color: AppColors.sectionSkill,
    ),
    OnboardingPage(
      title: "Master Your Finances",
      description: "Manage budgets, track expenses, and grow your wealth with smart insights.",
      icon: Icons.account_balance_wallet_rounded, 
      color: AppColors.sectionMoney,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Animation (Simplified for performance, can be enhanced)
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  _pages[_currentPage].color.withOpacity(0.1),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      child: const Text(
                        "Skip",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

                // Content Area
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => _buildIndicator(index == _currentPage),
                        ),
                      ),

                      // Next/Get Started Button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: _pages[_currentPage].color.withOpacity(0.4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_currentPage != _pages.length - 1)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.arrow_forward_rounded, size: 20),
                              ),
                          ],
                        ),
                      ),
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

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Illustration Area
          SizedBox(
            height: 300,
            width: double.infinity,
            child: _buildCustomIllustration(index, page.color),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.displayLarge?.color,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
              wordSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Custom visual compositions for each slide to look "Premium" without assets
  Widget _buildCustomIllustration(int index, Color color) {
    switch (index) {
      case 0: // Balance Your Life - 6 Pillars Composition
        return Stack(
          alignment: Alignment.center,
          children: [
             // Center Circle (Self)
             Container(
               width: 80, height: 80,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: Theme.of(context).cardColor,
                 boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
                 ],
               ),
               child: Icon(Icons.person_rounded, size: 40, color: Theme.of(context).textTheme.titleLarge?.color),
             ),
             // Orbiting Pillars
             ...List.generate(6, (i) {
                final angle = (i * 60) * 3.14159 / 180;
                final radius = 110.0;
                final offset = Offset(radius * -1 *  (i % 2 == 0 ? 1 : 0.8) *  (i > 2 ? -1 : 1), 0); // Simplified positioning logic visually
                // Proper circular positioning:
                // x = r * cos(angle), y = r * sin(angle)
                 final x = radius *  (i == 0 || i == 3 ? 1 : 0.5) * (i > 0 && i < 4 ? 1 : -1); 
                 // Let's use a simpler Positioned relative to center using alignments or Transform
                 // Or just hardcode beautiful positions for 6 items around a circle
                 return Transform.translate(
                   offset: Offset(
                     radius *  (i == 0 ? 1 : (i==1?0.5:(i==2?-0.5:(i==3?-1:(i==4?-0.5:0.5))))),
                     radius *  (i == 0 ? 0 : (i==1?0.866:(i==2?0.866:(i==3?0:(i==4?-0.866:-0.866))))),
                   ),
                   child: _buildMiniPillarIcon(i),
                 );
             }),
          ],
        );
      case 1: // Build Habits - Streak Flame & Graph
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background Graph Line (static)
            CustomPaint(
              size: const Size(200, 100),
              painter: _SparklinePainter(color: color.withOpacity(0.3)),
            ),
            // Central Flame Card
            Container(
              width: 120, height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 60, color: color),
                  const SizedBox(height: 8),
                  Text("21 Days", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                  Text("Streak", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                ],
              ),
            ),
            // Floating Achievement Badge
             Positioned(
               right: 40, top: 40,
               child: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: const BoxDecoration(
                   color: AppColors.gold,
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
               ),
             ),
          ],
        );
      case 2: // Finance - Wallet & Coins
        return Stack(
          alignment: Alignment.center,
          children: [
            // Wallet Card
            Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 180, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.sectionMoney,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.sectionMoney.withOpacity(0.4), blurRadius: 20, offset: const Offset(0,10)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 50),
                ),
              ),
            ),
            // Coins
            Positioned(
              top: 40, right: 60,
              child: const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 40),
            ),
            // Up Arrow
            Positioned(
              bottom: 60, left: 60,
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.green, size: 30)
              ),
            ),
          ],
        );
      default:
        return Icon(Icons.star, size: 100, color: color);
    }
  }

  Widget _buildMiniPillarIcon(int index) {
    Color color;
    IconData icon;
    switch(index) {
      case 0: color = AppColors.sectionBody; icon = Icons.fitness_center; break;
      case 1: color = AppColors.sectionMind; icon = Icons.psychology; break;
      case 2: color = AppColors.sectionMoney; icon = Icons.attach_money; break;
      case 3: color = AppColors.sectionSkill; icon = Icons.lightbulb; break;
      case 4: color = AppColors.sectionRelationship; icon = Icons.favorite; break;
      case 5: color = AppColors.sectionDharma; icon = Icons.self_improvement; break;
      default: color = Colors.grey; icon = Icons.circle;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }


  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? _pages[_currentPage].color : Theme.of(context).dividerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive ? [
           BoxShadow(color: _pages[_currentPage].color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
        ] : [],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = 3;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.9, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.1, size.width, size.height * 0.2);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
