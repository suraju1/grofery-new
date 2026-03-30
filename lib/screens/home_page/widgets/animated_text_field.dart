import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/router/app_routes.dart';

class CustomAnimatedTextField extends StatelessWidget {
  final double height;
  final double horizontalPadding;

  const CustomAnimatedTextField({
    super.key,
    this.height = 50.0,
    this.horizontalPadding = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
      ),
      child: SizedBox(
        height: height,
        child: GestureDetector(
          onTap: () {
            GoRouter.of(context).push(AppRoutes.search);
          },
          child: Stack(
            children: [
              Directionality(
                textDirection:
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                child: AnimatedTextField(
                  animationDuration:
                      const Duration(milliseconds: 500), // faster typing speed
                  animationType: Animationtype.typer,
                  showCursor: true,
                  readOnly: true,
                  enabled: false,
                  hintTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.7),
                  ),
                  hintTexts: const [
                    'Rice',
                    'Oil',
                    'Sugar',
                    'Atta',
                    'Bread',
                    'Milk',
                    'Dal',
                    'Ghee',
                  ],
                  minLines: 1,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(24.0), // more rounded
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none),
                    fillColor: isDarkMode(context)
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14.0, right: 8.0),
                      child: Icon(
                        HeroiconsOutline.magnifyingGlass,
                        size: 22,
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      GoRouter.of(context).push(AppRoutes.shoppingList);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(right: 4.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        TablerIcons
                            .microphone, // More grocery friendly icon, or pencil
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
