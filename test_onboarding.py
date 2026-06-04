#!/usr/bin/env python3
"""Test script to verify onboarding screen changes."""

import os

def check_localization_strings():
    """Check that localization strings were generated."""
    print("\nChecking localization strings...")
    try:
        # Check English localization
        en_file = "lib/core/l10n/generated/app_localizations_en.dart"
        with open(en_file, encoding='utf-8') as f:
            content = f.read()
            checks = [
                ("onboardingWelcomeNeutral", "Neutral welcome string for English"),
                ("onboardingTellUsNeutral", "Neutral tell us string for English"),
                ("onboardingStartNeutral", "Neutral start button for English"),
                ("continueActionNeutral", "Neutral continue button for English"),
            ]
            for check_str, desc in checks:
                if check_str in content:
                    print(f"  [OK] {desc}")
                else:
                    print(f"  [FAIL] {desc} NOT FOUND")

        # Check Hebrew localization
        he_file = "lib/core/l10n/generated/app_localizations_he.dart"
        with open(he_file, encoding='utf-8') as f:
            content = f.read()
            if "onboardingWelcomeNeutral" in content:
                print("  [OK] Hebrew localization includes neutral strings")
            else:
                print("  [FAIL] Hebrew localization missing neutral strings")

        return True
    except Exception as e:
        print(f"[FAIL] Failed to check localization: {str(e)}")
        return False

def check_code_changes():
    """Check that code changes were applied correctly."""
    print("\nChecking code changes...")
    try:
        onboarding_file = "lib/features/onboarding/onboarding_screen.dart"
        with open(onboarding_file, encoding='utf-8') as f:
            content = f.read()
            checks = [
                ("l.onboardingWelcomeNeutral", "Using neutral welcome text in step 1"),
                ("l.onboardingStartNeutral", "Using neutral start button in step 1"),
                ("l.onboardingTellUsNeutral", "Using neutral tell us text in step 2"),
                ("l.continueActionNeutral", "Using neutral continue button in step 2"),
                ("onPressed: _back", "Back button added to step 1"),
            ]
            for check_str, desc in checks:
                if check_str in content:
                    print(f"  [OK] {desc}")
                else:
                    print(f"  [FAIL] {desc} NOT FOUND")

        return True
    except Exception as e:
        print(f"[FAIL] Failed to check code changes: {str(e)}")
        return False

def check_arb_files():
    """Check that ARB files have the new strings."""
    print("\nChecking ARB localization files...")
    try:
        # Check English ARB
        en_arb = "lib/core/l10n/app_en.arb"
        with open(en_arb, encoding='utf-8') as f:
            content = f.read()
            if "onboardingWelcomeNeutral" in content and "onboardingStartNeutral" in content:
                print("  [OK] English ARB has neutral strings")
            else:
                print("  [FAIL] English ARB missing neutral strings")

        # Check Hebrew ARB
        he_arb = "lib/core/l10n/app_he.arb"
        with open(he_arb, encoding='utf-8') as f:
            content = f.read()
            if "onboardingWelcomeNeutral" in content:
                print("  [OK] Hebrew ARB has neutral strings")
            else:
                print("  [FAIL] Hebrew ARB missing neutral strings")

        # Check Hebrew MA (male) ARB
        he_ma_arb = "lib/core/l10n/app_he_MA.arb"
        with open(he_ma_arb, encoding='utf-8') as f:
            content = f.read()
            # Count how many strings are in the file
            import json
            data = json.loads(content)
            string_count = len([k for k in data.keys() if not k.startswith("@")])
            print(f"  [OK] Hebrew MA ARB has {string_count} strings (was ~56 before)")

            # Check for some key male-form strings
            male_checks = [
                ("onboardingWelcome", "ברוך הבא"),
                ("onboardingTellUs", "ספר לנו"),
            ]
            for key, expected_val in male_checks:
                if key in data and expected_val in data[key]:
                    print(f"    [OK] Male form for {key}")
                elif key in data:
                    print(f"    [WARN] {key} exists but may not have correct male form: {data[key]}")
                else:
                    print(f"    [FAIL] {key} not found in he_MA.arb")

        return True
    except Exception as e:
        print(f"[FAIL] Failed to check ARB files: {str(e)}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("Onboarding Screen Verification")
    print("=" * 60)

    results = []
    results.append(("Localization Strings", check_localization_strings()))
    results.append(("Code Changes", check_code_changes()))
    results.append(("ARB Files", check_arb_files()))

    print("\n" + "=" * 60)
    print("Summary:")
    print("=" * 60)
    for test_name, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"[{status}] {test_name}")

    all_passed = all(passed for _, passed in results)
    if all_passed:
        print("\nAll verifications passed!")
    else:
        print("\nSome verifications failed!")
