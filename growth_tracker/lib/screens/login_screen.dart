import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:growth_tracker/providers/user_provider.dart';
import 'package:growth_tracker/screens/main_shell.dart';
import 'package:growth_tracker/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedFocusArea = '';

  final List<Map<String, dynamic>> _focusAreas = [
    {
      'label': 'Health',
      'subtitle': 'Body, fitness and vitality',
      'icon': Icons.favorite_rounded,
      'value': 'Sağlık',
      'color': AppColors.categoryHealth,
    },
    {
      'label': 'Career',
      'subtitle': 'Growth and productivity',
      'icon': Icons.trending_up_rounded,
      'value': 'Kariyer',
      'color': AppColors.categoryCareer,
    },
    {
      'label': 'Mind',
      'subtitle': 'Clarity, focus and calm',
      'icon': Icons.psychology_rounded,
      'value': 'Zihinsel',
      'color': AppColors.categoryMind,
    },
    {
      'label': 'Wealth',
      'subtitle': 'Financial intelligence',
      'icon': Icons.account_balance_rounded,
      'value': 'Finansal',
      'color': AppColors.categoryFinancial,
    },
    {
      'label': 'Creative',
      'subtitle': 'Conscious creation',
      'icon': Icons.auto_awesome_rounded,
      'value': 'Mindfulness',
      'color': AppColors.categoryMindfulness,
    },
    {
      'label': 'Social',
      'subtitle': 'Glowing connections',
      'icon': Icons.people_rounded,
      'value': 'Öğrenme',
      'color': AppColors.categoryLearning,
    },
  ];

  void _nextPage() {
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      _showSnack('Please enter your name');
      return;
    }
    if (_currentPage == 1) {
      if (_jobController.text.trim().isEmpty) {
        _showSnack('Please enter your profession');
        return;
      }
      if (int.tryParse(_ageController.text) == null) {
        _showSnack('Please enter a valid age');
        return;
      }
    }
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _finish() async {
    if (_selectedFocusArea.isEmpty) {
      _showSnack('Please select a growth focus area');
      return;
    }

    await context.read<UserProvider>().syncUser(
          name: _nameController.text.trim(),
          job: _jobController.text.trim(),
          age: int.parse(_ageController.text),
          focusArea: _selectedFocusArea,
        );

    if (!mounted) return;

    final error = context.read<UserProvider>().error;
    if (error != null) {
      _showSnack('Error: $error');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _jobController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      const _AppLogo(),
                      const Spacer(),
                      Text(
                        'Step ${_currentPage + 1} of 3',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: i <= _currentPage
                                ? AppColors.gradientPrimary
                                : null,
                            color: i <= _currentPage
                                ? null
                                : AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
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

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Define your\npresence.',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Before we begin, help us curate your\nmental landscape with a few simple details.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _sectionLabel('Personal Identity'),
          const SizedBox(height: 12),
          _darkTextField(
            controller: _nameController,
            hint: 'What should we call you?',
            label: 'Your Name',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1F5F), Color(0xFF1A1830)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your data is a\nprivate sanctuary.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _primaryButton('Next Chapter →', _nextPage),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shape your\nidentity.',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A few more details help us personalize\nyour cognitive journey.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _sectionLabel('Personal Identity'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _darkTextField(
                  controller: _ageController,
                  hint: '27',
                  label: 'Age',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _darkTextField(
                  controller: TextEditingController(text: 'UTC-5:30'),
                  hint: 'UTC-5:30',
                  label: 'Timezone',
                  enabled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _darkTextField(
            controller: _jobController,
            hint: 'Creative Architect, Developer...',
            label: 'Your Profession',
          ),
          const Spacer(),
          _primaryButton('Next Chapter →', _nextPage),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final userProvider = context.watch<UserProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Growth\nFocus Area',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select multiple',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: _focusAreas.map((area) {
                final selected = _selectedFocusArea == area['value'];
                final color = area['color'] as Color;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedFocusArea = area['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? color : AppColors.cardBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  area['icon'] as IconData,
                                  color: color,
                                  size: 16,
                                ),
                              ),
                              if (selected) ...[
                                const Spacer(),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Spacer(),
                          Text(
                            area['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? color : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            area['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            userProvider.isLoading ? '' : 'Next Chapter →',
            userProvider.isLoading ? null : _finish,
            loading: userProvider.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed,
      {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? AppColors.gradientPrimary
              : const LinearGradient(
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.surfaceElevated
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.psychology_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        const Text(
          'Cognitive Sanctuary',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
