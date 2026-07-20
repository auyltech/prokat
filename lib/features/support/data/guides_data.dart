import 'package:prokat/features/support/models/guide_icon.dart';
import 'package:prokat/features/support/models/user_guide.dart';

final guides = [
  UserGuide(
    id: 'getting_started',
    slug: 'getting-started',
    category: 'GETTING_STARTED',
    icon: GuideIcon.gettingStarted,
    order: 1,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Getting Started',
        summary: 'Learn the basics of using Prokat.',
        content: '''
# Getting Started

Welcome to **Prokat**, a marketplace where you can rent equipment from trusted owners or list your own equipment for others to rent.

## Create your account

Sign in using your phone number and complete your profile.

## Browse equipment

Explore categories or search for equipment that fits your needs.

## Send a booking request

Choose your rental period and submit a booking request.

## Stay informed

Enable notifications to receive updates about your bookings, requests, and messages.
''',
      ),
      const UserGuideTranslation(
        locale: 'ru',
        title: '',
        summary: '',
        content: '',
      ),
      const UserGuideTranslation(
        locale: 'kk',
        title: '',
        summary: '',
        content: '',
      ),
    ],
  ),

  UserGuide(
    id: 'renting',
    slug: 'renting-equipment',
    category: 'RENTING',
    icon: GuideIcon.booking,
    order: 2,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Renting Equipment',
        summary: 'Everything you need to know before renting.',
        content: '''
# Renting Equipment

Renting equipment through Prokat is quick and straightforward.

## Find equipment

Use search or browse categories to discover available equipment.

## Review the details

Read the description, rental conditions, pricing, and equipment location before sending a request.

## Send a request

Choose your rental dates and submit your booking request.

## Wait for the owner's response

The owner may approve, reject, or negotiate your request.

## Complete your rental

Inspect the equipment before use and return it in the agreed condition.
''',
      ),
      const UserGuideTranslation(
        locale: 'ru',
        title: '',
        summary: '',
        content: '',
      ),
      const UserGuideTranslation(
        locale: 'kk',
        title: '',
        summary: '',
        content: '',
      ),
    ],
  ),

  UserGuide(
    id: 'listing',
    slug: 'listing-equipment',
    category: 'LISTING',
    icon: GuideIcon.equipment,
    order: 3,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Listing Your Equipment',
        summary: 'Start earning by renting out your equipment.',
        content: '''
# Listing Your Equipment

Anyone can become an equipment owner on Prokat.

## Add equipment

Provide accurate information, upload clear photos, and choose the correct category.

## Set your pricing

Configure rental prices that reflect your equipment and market conditions.

## Manage bookings

Review incoming requests and respond promptly.

## Keep your listings updated

Update availability, pricing, and equipment information whenever changes occur.
''',
      ),
      const UserGuideTranslation(
        locale: 'ru',
        title: '',
        summary: '',
        content: '',
      ),
      const UserGuideTranslation(
        locale: 'kk',
        title: '',
        summary: '',
        content: '',
      ),
    ],
  ),

  UserGuide(
    id: 'payments',
    slug: 'payments-pricing',
    category: 'PAYMENTS',
    icon: GuideIcon.payments,
    order: 4,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Payments & Pricing',
        summary: 'Understand rental prices and payments.',
        content: '''
# Payments & Pricing

Rental prices are determined by equipment owners.

## Rental price

Each equipment listing displays its available rental rates.

## Additional costs

Delivery fees or other charges may apply if agreed with the owner.

## Review before confirming

Always verify the total cost before submitting your booking request.
''',
      ),
      const UserGuideTranslation(
        locale: 'ru',
        title: '',
        summary: '',
        content: '',
      ),
      const UserGuideTranslation(
        locale: 'kk',
        title: '',
        summary: '',
        content: '',
      ),
    ],
  ),

  UserGuide(
    id: 'safety',
    slug: 'safety-trust',
    category: 'SAFETY',
    icon: GuideIcon.safety,
    order: 5,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Safety & Trust',
        summary: 'Best practices for safe rentals.',
        content: '''
# Safety & Trust

Following these recommendations helps ensure a positive rental experience.

## Inspect equipment

Check the equipment before accepting and before returning it.

## Report problems

Notify the owner immediately if you notice any issues.

## Respect agreements

Return equipment on time and in the same condition in which you received it.

## Stay within Prokat

Use Prokat's communication tools whenever possible for rental-related discussions.
''',
      ),
      const UserGuideTranslation(
        locale: 'ru',
        title: '',
        summary: '',
        content: '',
      ),
      const UserGuideTranslation(
        locale: 'kk',
        title: '',
        summary: '',
        content: '',
      ),
    ],
  ),

  UserGuide(
    id: 'account',
    slug: 'account-settings',
    category: 'ACCOUNT',
    icon: GuideIcon.account,
    order: 6,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Account & Settings',
        summary: 'Manage your profile and preferences.',
        content: '''
# Account & Settings

Your account allows you to manage your personal information and preferences.

## Profile

Keep your name and profile information up to date.

## Notifications

Enable notifications to stay informed about bookings, requests, and messages.

## Privacy

Review the Privacy Policy and Terms & Conditions from the Help & Support section.

## Need assistance?

If you have questions or encounter a problem, contact our support team through the Help & Support screen.
''',
      ),
      const UserGuideTranslation(
        locale: 'ru',
        title: '',
        summary: '',
        content: '',
      ),
      const UserGuideTranslation(
        locale: 'kk',
        title: '',
        summary: '',
        content: '',
      ),
    ],
  ),
];
