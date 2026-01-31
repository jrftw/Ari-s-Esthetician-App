/*
 * Filename: terms_and_conditions.dart
 * Purpose: Pennsylvania-specific Terms & Conditions content for esthetician services
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: None
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Terms & Conditions Content
/// Pennsylvania-specific Terms & Conditions for Arianna DeAngelis esthetician services
/// This content must be displayed and accepted before booking submission
class TermsAndConditions {
  TermsAndConditions._(); // Private constructor to prevent instantiation

  /// Business name
  static const String businessName = 'Arianna DeAngelis';

  /// Full Terms & Conditions text (Pennsylvania-specific)
  static const String fullText = '''
ESTHETICIAN SERVICES TERMS & CONDITIONS (Pennsylvania)

By completing a booking with Arianna DeAngelis ("Business," "we," "us"), you ("Client," "you") acknowledge and agree to the following terms. Your booking constitutes acceptance of these Terms & Conditions.

1. SERVICES & SCOPE

You agree that all esthetic services provided are non-medical cosmetic/esthetic treatments (e.g., facials, waxing, skincare services) and are not medical procedures. You understand that no service is a substitute for medical diagnosis, treatment, or advice.

2. CLIENT HEALTH DISCLOSURE & REPRESENTATIONS

You represent that you have provided accurate and complete information regarding your medical history, allergies, medications, skin conditions, pregnancy status, sensitivities, and any other factors relevant to your care.
You understand that failure to fully disclose accurate information may increase the risk of adverse reactions or outcomes, and you accept responsibility for such nondisclosure.

3. ASSUMPTION OF RISK & POSSIBLE OUTCOMES

You acknowledge that esthetic services carry inherent risks, including but not limited to skin irritation, redness, swelling, allergic or sensitivity reactions, scarring, infection, or other complications. You voluntarily assume all such risks by booking and receiving services.

4. INFORMED CONSENT

By booking, you confirm that:

You have read, understand, and accept general descriptions of the services requested.

You understand the expected benefits, risks, and possible side effects.

You agree to proceed with the requested services knowing these risks.

This informed consent applies to all esthetic services booked and performed.

5. RELEASE OF LIABILITY

To the fullest extent permitted under Pennsylvania law, you agree that Arianna DeAngelis, its owners, agents, employees, independent contractors, and affiliates shall not be liable for any damages, injuries, losses, claims, or expenses arising directly or indirectly from:

Any services rendered,

Use of products during services,

Failure to follow aftercare or pre-service instructions,

Reactions related to undisclosed health information,

Any adverse outcomes or complications.

You hereby release and discharge the Business from any and all such claims.

6. NO GUARANTEE OF RESULTS

You acknowledge that results vary by individual factors (skin type, lifestyle, aftercare, etc.) and that the Business makes no guarantees or warranties regarding results or outcomes, whether express or implied.

7. PAYMENT, DEPOSITS & FEES

You agree that full payment is due at the time of service unless otherwise agreed in writing.

If a deposit is required to secure your appointment, that deposit is non-refundable except at the Business's sole discretion.

You authorize the Business to charge any outstanding balance due at the time of service.

8. CANCELLATION, RESCHEDULING & NO-SHOWS

Cancellations or rescheduling requests must be made at least 24 hours prior to the appointment time.

Failure to cancel within this time window or failure to appear ("no-show") may result in forfeiture of your deposit and/or the right to charge the full service fee.

Repeated no-shows or late cancellations may result in refusal of future bookings.

9. CLIENT OBLIGATIONS

You agree to:

Follow all pre-service and aftercare instructions provided by the Business.

Inform the esthetician of any changes to your health, medications, or allergies before the service begins.

Accept responsibility for outcomes resulting from failure to follow instructions.

10. RIGHT TO REFUSE OR TERMINATE SERVICE

The Business reserves the right to refuse or discontinue services at any time, including but not limited to situations where:

Your health, safety, or wellbeing is at risk;

You fail to comply with policies or instructions;

Your behavior is inappropriate, disruptive, or unsafe.

11. AGE REQUIREMENTS

Clients must be at least 18 years old to book esthetic services. If under 18, a parent or legal guardian must facilitate booking and consent.

12. ELECTRONIC ACCEPTANCE

Your booking, scheduling, or continued use of services constitutes electronic acceptance of these Terms & Conditions as though signed in writing. This acceptance is legally binding in Pennsylvania.

13. GOVERNING LAW

These Terms & Conditions shall be governed by and interpreted under the laws of the Commonwealth of Pennsylvania without regard to conflicts of law principles.

14. SEVERABILITY

If any provision of these Terms is held invalid or unenforceable, the remaining provisions shall remain in full force and effect.
''';

  /// Consent text to display next to Terms & Conditions checkbox
  static const String consentText = 
      'By booking, I acknowledge and agree to the Terms & Conditions, including informed consent, assumption of risk, and release of liability.';

  /// Cancellation/no-show policy version for snapshot at submission time
  static const String cancellationPolicyVersion = '1.0';

  /// Get formatted terms for display in UI
  static String getFormattedTerms() {
    return fullText;
  }
}

// Suggestions For Features and Additions Later:
// - Add version tracking for terms updates
// - Add terms acceptance history
// - Add ability to download terms as PDF
// - Add multi-language support
// - Add terms update notifications
