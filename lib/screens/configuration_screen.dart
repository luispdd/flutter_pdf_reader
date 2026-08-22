import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../controllers/document_reader_controller.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  late double _speechRate;
  String? _selectedLanguage;
  List<String> _languages = [];
  bool _isLoadingLanguages = true;

  @override
  void initState() {
    super.initState();
    final controller = context.read<DocumentReaderController>();
    _speechRate = controller.speechRate;
    _selectedLanguage = controller.speechLanguage;
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    final controller = context.read<DocumentReaderController>();
    final list = await controller.getAvailableLanguages();
    if (mounted) {
      setState(() {
        _languages = list;
        _isLoadingLanguages = false;
        // If current selected language is not in list and list is not empty, keep it in the list
        if (_selectedLanguage != null &&
            _languages.isNotEmpty &&
            !_languages.contains(_selectedLanguage)) {
          _languages.insert(0, _selectedLanguage!);
        }
      });
    }
  }

  Future<void> _applySettings() async {
    final controller = context.read<DocumentReaderController>();
    await controller.updateSpeechSettings(
      speechRate: _speechRate,
      language: _selectedLanguage,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration applied successfully'),
        backgroundColor: kAmberDark,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(title: const Text('Configuration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Narration Speed Section ───
              _buildSectionCard(
                title: 'Narration Speed',
                subtitle: 'Control how fast or slow the voice reads',
                icon: Icons.speed_rounded,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Speech Rate',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kAmber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${_speechRate.toStringAsFixed(2)}x',
                            style: const TextStyle(
                              color: kAmberLight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _speechRate.clamp(0.25, 2.0),
                      min: 0.25,
                      max: 2.0,
                      divisions: 35, // 0.05 step
                      label: '${_speechRate.toStringAsFixed(2)}x',
                      onChanged: (value) {
                        setState(() {
                          _speechRate = double.parse(value.toStringAsFixed(2));
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0.25x (Slower)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '1.0x (Normal)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '2.0x (Faster)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Quick presets
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [0.5, 0.65, 0.8, 1.0, 1.25, 1.5].map((rate) {
                        final isSelected = (_speechRate - rate).abs() < 0.01;
                        return ChoiceChip(
                          label: Text('${rate}x'),
                          selected: isSelected,
                          selectedColor: kAmber.withValues(alpha: 0.25),
                          backgroundColor: kBgDark,
                          labelStyle: TextStyle(
                            color: isSelected ? kAmberLight : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected ? kAmber : Colors.white12,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _speechRate = rate;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Narration Language Section ───
              _buildSectionCard(
                title: 'Narration Language',
                subtitle: 'Select the voice language for text-to-speech',
                icon: Icons.language_rounded,
                child: _isLoadingLanguages
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: kAmber,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kBgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                isExpanded: true,
                                value: _selectedLanguage,
                                dropdownColor: kSurface,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: kAmber,
                                ),
                                hint: Text(
                                  'System Default',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      'System Default',
                                      style: TextStyle(
                                        color: _selectedLanguage == null
                                            ? kAmberLight
                                            : kTextPrimary,
                                        fontWeight: _selectedLanguage == null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  ..._languages.map(
                                    (lang) => DropdownMenuItem<String?>(
                                      value: lang,
                                      child: Text(
                                        lang,
                                        style: TextStyle(
                                          color: _selectedLanguage == lang
                                              ? kAmberLight
                                              : kTextPrimary,
                                          fontWeight: _selectedLanguage == lang
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLanguage = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          if (_languages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'No additional system TTS languages detected. Using default voice.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              const SizedBox(height: 32),

              // ─── Apply Button ───
              ElevatedButton(
                onPressed: _applySettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: kAmber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
