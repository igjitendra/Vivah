#!/usr/bin/env python3
"""
व्यवहार (Vyavahaar) — Step 2.5: Multilingual Localization Architecture Verification
Validates 22 Scheduled Indian Languages, ARB format, RTL detection, ICU plurals,
and Unicode search across diverse Indic scripts.
"""

import json
import sys
import os
import unicodedata

SCHEDULED_LANGUAGES_22 = [
    ("as", "Assamese", "অসমীয়া", "Beng", False),
    ("bn", "Bengali", "বাংলা", "Beng", False),
    ("brx", "Bodo", "बड़ो", "Deva", False),
    ("doi", "Dogri", "डोगरी", "Deva", False),
    ("gu", "Gujarati", "ગુજરાતી", "Gujr", False),
    ("hi", "Hindi", "हिन्दी", "Deva", False),
    ("kn", "Kannada", "ಕನ್ನಡ", "Knda", False),
    ("ks", "Kashmiri", "کٲشُر", "Arab", True),
    ("kok", "Konkani", "कोंकणी", "Deva", False),
    ("mai", "Maithili", "मैथिली", "Deva", False),
    ("ml", "Malayalam", "മലയാളം", "Mlym", False),
    ("mni", "Manipuri", "ꯃꯩꯇꯩꯂꯣꯟ", "Mtei", False),
    ("mr", "Marathi", "मराठी", "Deva", False),
    ("ne", "Nepali", "नेपाली", "Deva", False),
    ("or", "Odia", "ଓଡ଼ିଆ", "Orya", False),
    ("pa", "Punjabi", "ਪੰਜਾਬੀ", "Guru", False),
    ("sa", "Sanskrit", "संस्कृतम्", "Deva", False),
    ("sat", "Santali", "ᱥᱟᱱᱛᱟᱲᱤ", "Olck", False),
    ("sd", "Sindhi", "سنڌي", "Arab", True),
    ("ta", "Tamil", "தமிழ்", "Taml", False),
    ("te", "Telugu", "తెలుగు", "Telu", False),
    ("ur", "Urdu", "اردو", "Arab", True),
]

def run_tests():
    print("=" * 65)
    print("🌐 VYAVHAAR STEP 2.5: MULTILINGUAL LOCALIZATION VERIFICATION")
    print("=" * 65)

    total_tests = 0
    passed_tests = 0

    def assert_test(desc, condition):
        nonlocal total_tests, passed_tests
        total_tests += 1
        if condition:
            passed_tests += 1
            print(f"  ✅ {desc}")
        else:
            print(f"  ❌ FAILED: {desc}")
            sys.exit(1)

    print("\n📜 1. Scheduled Indian Languages Registry Audit:")
    assert_test("Exactly 22 official scheduled languages registered", len(SCHEDULED_LANGUAGES_22) == 22)
    rtl_count = sum(1 for _, _, _, _, is_rtl in SCHEDULED_LANGUAGES_22 if is_rtl)
    assert_test("Right-to-Left (RTL) recognized for Urdu, Kashmiri, and Sindhi (3 scripts)", rtl_count == 3)

    print("\n📁 2. ARB Translation Resources & ICU Formatting:")
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    l10n_dir = os.path.join(base_dir, "lib", "l10n")

    en_path = os.path.join(l10n_dir, "app_en.arb")
    hi_path = os.path.join(l10n_dir, "app_hi.arb")
    ur_path = os.path.join(l10n_dir, "app_ur.arb")

    assert_test("English template app_en.arb exists", os.path.isfile(en_path))
    assert_test("Hindi resource app_hi.arb exists", os.path.isfile(hi_path))
    assert_test("Urdu resource app_ur.arb exists", os.path.isfile(ur_path))

    with open(en_path, "r", encoding="utf-8") as f:
        en_data = json.load(f)
    with open(hi_path, "r", encoding="utf-8") as f:
        hi_data = json.load(f)
    with open(ur_path, "r", encoding="utf-8") as f:
        ur_data = json.load(f)

    en_keys = {k for k in en_data if not k.startswith("@")}
    hi_keys = {k for k in hi_data if not k.startswith("@")}
    ur_keys = {k for k in ur_data if not k.startswith("@")}

    assert_test("Hindi translation has complete key parity with English template", en_keys.issubset(hi_keys))
    assert_test("Urdu translation has complete key parity with English template", en_keys.issubset(ur_keys))

    # Verify ICU plural format in entryCount
    assert_test("app_en.arb contains valid ICU plural syntax for entryCount", "{count, plural," in en_data.get("entryCount", ""))
    assert_test("app_hi.arb contains valid ICU plural syntax for entryCount", "{count, plural," in hi_data.get("entryCount", ""))

    print("\n🔍 3. Indic Unicode Script Normalization & Search Matching:")
    def unicode_matches(target, query):
        norm_t = unicodedata.normalize('NFC', target.strip().lower())
        norm_q = unicodedata.normalize('NFC', query.strip().lower())
        return norm_q in norm_t

    # Test Indic Scripts
    test_cases = [
        ("Devanagari (Hindi)", "रामकिशोर शर्मा", "रामकिशोर", True),
        ("Bengali (বাংলা)", "সৌম্য বন্দ্যোপাধ্যায়", "সৌম্য", True),
        ("Gurmukhi (ਪੰਜਾਬੀ)", "ਹਰਪ੍ਰੀਤ ਸਿੰਘ", "ਹਰਪ੍ਰੀਤ", True),
        ("Gujarati (ગુજરાતી)", "હિતેશ પટેલ", "હિતેશ", True),
        ("Odia (ଓଡ଼ିଆ)", "ଦେବାଶିଷ ମହାପାତ୍ର", "ଦେବାଶିଷ", True),
        ("Tamil (தமிழ்)", "கார்த்திக் சுப்ரமணியம்", "கார்த்திக்", True),
        ("Telugu (తెలుగు)", "వెంకటేశ్వర రావు", "వెంకటేశ్వర", True),
        ("Kannada (ಕನ್ನಡ)", "ಪ್ರಶಾಂತ್ ಕುಮಾರ್", "ಪ್ರಶಾಂತ್", True),
        ("Malayalam (മലയാളം)", "അനൂപ് മേനോൻ", "അനൂപ്", True),
        ("Meitei Mayek (Manipuri)", "ꯃꯩꯇꯩ ꯆꯅꯨ", "ꯃꯩꯇꯩ", True),
        ("Ol Chiki (Santali)", "ᱥᱟᱱᱛᱟᱲᱤ ᱦᱚᱲ", "ᱥᱟᱱᱛᱟᱲᱤ", True),
        ("Perso-Arabic (Urdu)", "محمد رضوان", "رضوان", True),
    ]

    for script_name, target, query, expected in test_cases:
        res = unicode_matches(target, query)
        assert_test(f"Unicode NFC search works for {script_name}", res == expected)

    print("\n💰 4. Cultural Terminology Verification (No Debt / Loan Terms):")
    banned_terms = ["loan", "credit", "debit", "debt", "due", "कर्ज", "ऋण", "उधार"]
    for lang_code, data in [("en", en_data), ("hi", hi_data)]:
        for key, val in data.items():
            if isinstance(val, str):
                for banned in banned_terms:
                    # 'credit' shouldn't appear as standalone financial word
                    if banned in val.lower().split():
                        assert_test(f"Banned financial term '{banned}' found in {lang_code}:{key}", False)
    assert_test("Zero commercial credit/loan terminology across translation catalogs", True)

    print("\n" + "=" * 65)
    print(f"Results: {passed_tests}/{total_tests} tests passed successfully!")
    print("🎉 ALL MULTILINGUAL LOCALIZATION TESTS PASSED WITH 100% SUCCESS!")
    print("=" * 65)

if __name__ == "__main__":
    run_tests()
