import 'package:mediverse/common/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLanguageOption {
  final String label;
  final String code;
  final Locale locale;

  const AppLanguageOption({
    required this.label,
    required this.code,
    required this.locale,
  });
}

class LanguageUtils {
  static const List<AppLanguageOption> options = <AppLanguageOption>[
    AppLanguageOption(
      label: 'English',
      code: 'en_US',
      locale: Locale('en', 'US'),
    ),
    AppLanguageOption(
      label: 'Hindi (हिंदी)',
      code: 'hi_IN',
      locale: Locale('hi', 'IN'),
    ),
    AppLanguageOption(
      label: 'Marathi (मराठी)',
      code: 'mr_IN',
      locale: Locale('mr', 'IN'),
    ),
    AppLanguageOption(
      label: 'Kannada (ಕನ್ನಡ)',
      code: 'kn_IN',
      locale: Locale('kn', 'IN'),
    ),
    AppLanguageOption(
      label: 'Punjabi (ਪੰਜਾਬੀ)',
      code: 'pa_IN',
      locale: Locale('pa', 'IN'),
    ),
  ];

  static String labelFromCode(String code) {
    final match = options.where((o) => o.code == code);
    if (match.isNotEmpty) return match.first.label;
    return 'English';
  }

  static Future<void> applyLanguageByLabel(String label) async {
    final selected = options.firstWhere(
      (o) => o.label == label,
      orElse: () => options.first,
    );
    final storage = await StorageService.getInstance();
    Get.updateLocale(selected.locale);
    await storage.saveLanguage(selected.code);
  }

  static void showLanguageSelector(
    BuildContext context, {
    required String selectedLabel,
    required ValueChanged<String> onSelected,
    Color accentColor = const Color(0xFF6A9C89),
    Color backgroundColor = Colors.white,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_language'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 10),
              ...options.map(
                (lang) => ListTile(
                  title: Text(
                    lang.label,
                    style: TextStyle(
                      fontWeight: selectedLabel == lang.label
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedLabel == lang.label
                          ? accentColor
                          : Colors.black87,
                    ),
                  ),
                  trailing: selectedLabel == lang.label
                      ? Icon(Icons.check_circle, color: accentColor)
                      : null,
                  onTap: () async {
                    onSelected(lang.label);
                    await applyLanguageByLabel(lang.label);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
