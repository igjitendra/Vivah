# Language Support Matrix — व्यवहार (Vyavahaar)

> **Standard Compliance**: BCP 47, ISO 639-1/2/3, ISO 15924 (Scripts), Unicode CLDR v44.  
> **Eighth Schedule Coverage**: 22 / 22 Official Scheduled Indian Languages + English Fallback.  
> **Last Updated**: 2026-11-21  

---

## 1. Full 22 Scheduled Indian Languages Matrix

| # | English Name | Native Name | BCP 47 Tag | Script (ISO 15924) | Direction | Primary Font Family | Translation Status | Native Review | UI Coverage | Production Status |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **0** | **English** | English | `en-IN` | Latin (`Latn`) | LTR | Roboto | Released | Approved | 100% | **PRODUCTION READY** |
| **1** | **Hindi** | हिन्दी | `hi-IN` | Devanagari (`Deva`) | LTR | NotoSansDevanagari | Released | Approved | 100% | **PRODUCTION READY** |
| **2** | **Assamese** | অসমীয়া | `as-IN` | Bengali-Assamese (`Beng`) | LTR | NotoSansBengali | Draft | Pending | Catalog Ready | Architecture Ready |
| **3** | **Bengali** | বাংলা | `bn-IN` | Bengali (`Beng`) | LTR | NotoSansBengali | Draft | Pending | Catalog Ready | Architecture Ready |
| **4** | **Bodo** | बड़ो | `brx-Deva-IN`| Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **5** | **Dogri** | डोगरी | `doi-Deva-IN`| Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **6** | **Gujarati** | ગુજરાતી | `gu-IN` | Gujarati (`Gujr`) | LTR | NotoSansGujarati | Draft | Pending | Catalog Ready | Architecture Ready |
| **7** | **Kannada** | ಕನ್ನಡ | `kn-IN` | Kannada (`Knda`) | LTR | NotoSansKannada | Draft | Pending | Catalog Ready | Architecture Ready |
| **8** | **Kashmiri (Arabic)**| کٲشُر | `ks-Arab-IN`| Perso-Arabic (`Arab`) | **RTL** | NotoNastaliqUrdu | Draft | Pending | Catalog Ready | Architecture Ready |
| **9** | **Kashmiri (Deva)** | कॉशुर | `ks-Deva-IN`| Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **10**| **Konkani** | कोंकणी | `kok-Deva-IN`| Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **11**| **Maithili** | मैथिली | `mai-Deva-IN`| Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **12**| **Malayalam** | മലയാളം | `ml-IN` | Malayalam (`Mlym`) | LTR | NotoSansMalayalam | Draft | Pending | Catalog Ready | Architecture Ready |
| **13**| **Manipuri (Meitei)**| ꯃꯩꯇꯩꯂꯣꯟ | `mni-Mtei-IN`| Meitei Mayek (`Mtei`)| LTR | NotoSansMeeteiMayek | Draft | Pending | Catalog Ready | Architecture Ready |
| **14**| **Manipuri (Beng)** | মৈতৈলোন্ | `mni-Beng-IN`| Bengali (`Beng`) | LTR | NotoSansBengali | Draft | Pending | Catalog Ready | Architecture Ready |
| **15**| **Marathi** | मराठी | `mr-IN` | Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **16**| **Nepali** | नेपाली | `ne-IN` | Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **17**| **Odia** | ଓଡ଼ିଆ | `or-IN` | Odia (`Orya`) | LTR | NotoSansOriya | Draft | Pending | Catalog Ready | Architecture Ready |
| **18**| **Punjabi** | ਪੰਜਾਬੀ | `pa-Guru-IN`| Gurmukhi (`Guru`) | LTR | NotoSansGurmukhi | Draft | Pending | Catalog Ready | Architecture Ready |
| **19**| **Sanskrit** | संस्कृतम् | `sa-Deva-IN`| Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **20**| **Santali** | ᱥᱟᱱᱛᱟᱲᱤ | `sat-Olck-IN`| Ol Chiki (`Olck`) | LTR | NotoSansOlChiki | Draft | Pending | Catalog Ready | Architecture Ready |
| **21**| **Sindhi (Arabic)** | سنڌي | `sd-Arab-IN`| Perso-Arabic (`Arab`) | **RTL** | NotoNastaliqUrdu | Draft | Pending | Catalog Ready | Architecture Ready |
| **22**| **Sindhi (Deva)** | सिन्धी | `sd-Deva-IN`| Devanagari (`Deva`) | LTR | NotoSansDevanagari | Draft | Pending | Catalog Ready | Architecture Ready |
| **23**| **Tamil** | தமிழ் | `ta-IN` | Tamil (`Taml`) | LTR | NotoSansTamil | Draft | Pending | Catalog Ready | Architecture Ready |
| **24**| **Telugu** | తెలుగు | `te-IN` | Telugu (`Telu`) | LTR | NotoSansTelugu | Draft | Pending | Catalog Ready | Architecture Ready |
| **25**| **Urdu** | اردو | `ur-IN` | Perso-Arabic (`Arab`) | **RTL** | NotoNastaliqUrdu | Draft | Pending | Catalog Ready | Architecture Ready |

---

## 2. Extensible Regional Languages (Roadmap)

The following non-scheduled regional Indian languages and dialects are supported by the `LanguageRegistry.registerLanguage()` API:
- **Bhojpuri** (`bho-Deva-IN`): Eastern UP, Bihar.
- **Rajasthani / Marwari** (`raj-Deva-IN`): Rajasthan.
- **Tulu** (`tcy-Knda-IN`): Coastal Karnataka.
- **Khasi** (`kha-Latn-IN`): Meghalaya.
- **Garo** (`grt-Latn-IN`): Meghalaya.
- **Mizo** (`lus-Latn-IN`): Mizoram.

---

## 3. Strict Verification & Integrity Rule

Under NO circumstances shall a language be flagged as `PRODUCTION READY` without:
1. Native speaker review of all financial terms (*Given, Received, Transactions, Cash, Gift estimates*).
2. Physical device font rendering audit verifying zero clipping or broken conjuncts (*yuktakshars*).
3. Visual confirmation of RTL alignment for Arabic-script variants.
