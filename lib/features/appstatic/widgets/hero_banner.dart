import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstatic/state/guest_city_prompt.dart';
import 'package:prokat/features/appstatic/widgets/login_tile.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class HeroBanner extends ConsumerStatefulWidget {
  final String selectedCity;

  const HeroBanner({super.key, required this.selectedCity});

  @override
  ConsumerState<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  late final Animation<double> _shakeX;
  bool _showCityError = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _promptCity() {
    setState(() => _showCityError = true);
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlueBg = Color(0xFF071D49);
    final l10n = AppLocalizations.of(context)!;
    final hasCity = widget.selectedCity.trim().isNotEmpty;
    final showError = _showCityError && !hasCity;

    ref.listen(guestCityPromptProvider, (previous, next) {
      if (previous == next) return;
      if ((ref.read(locationProvider).city ?? '').trim().isEmpty) {
        _promptCity();
      }
    });

    return Container(
      color: darkBlueBg,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.heroPlatformTag,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(180),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.heroTitle,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _shakeX,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeX.value, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => CityPickerSheet.show(
                context: context,
                service: CitySelectorService.guestcategory,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: showError
                        ? Theme.of(context).colorScheme.error
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasCity
                          ? catalogCityLabelOf(
                              ref,
                              context,
                              widget.selectedCity,
                            )
                          : l10n.selectCity,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const LoginTile(),
        ],
      ),
    );
  }
}
