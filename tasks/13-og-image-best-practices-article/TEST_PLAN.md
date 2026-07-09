# Test Plan: OG Image Best Practices Article

## Test Phases Overview

- **Phase 1:** Pre-publish format validation (markdown, links, metadata)
- **Phase 2:** Content accuracy & completeness (spec compliance, word counts, examples)
- **Phase 3:** Accessibility compliance (WCAG, contrast, alt text)
- **Phase 4:** Cross-platform validation (Facebook, Twitter, LinkedIn, Slack)

---

## Phase 1: Format & Structure Validation

### Test 1.1: Markdown Syntax Validation

**Description:** Verify markdown is valid and renders correctly.
**Steps:**

1. Check all heading levels (H1, H2, H3) are consistent
2. Verify code blocks use correct fence (```language)
3. Check table formatting (pipes, headers, separators)
4. Validate list formatting (bullets, numbering)
5. Verify links use proper markdown syntax

**Expected:** Zero markdown errors, clean rendering

### Test 1.2: Table of Contents Links

**Description:** Verify all TOC links point to valid sections.
**Steps:**

1. Check each TOC link references a valid section heading
2. Verify anchor IDs match heading text
3. Click/follow each link in markdown viewer

**Expected:** All 10 section links work correctly

### Test 1.3: Internal Link Validation

**Description:** Check all cross-references and internal links.
**Steps:**

1. Identify all internal references (e.g., "see Section 3.2")
2. Verify referenced sections exist
3. Verify section numbers match actual structure

**Expected:** All internal references accurate

### Test 1.4: File Encoding & Special Characters

**Description:** Verify file encoding and special characters.
**Steps:**

1. Check file encoding is UTF-8
2. Verify smart quotes, em dashes rendered correctly
3. Check copyright/trademark symbols display properly

**Expected:** All special characters display correctly

### Test 1.5: Code Snippet Formatting

**Description:** Validate all code examples render cleanly.
**Steps:**

1. Verify all code blocks have language identifiers
2. Check HTML/CSS code blocks highlight properly
3. Verify code is copy-paste compatible (no formatting artifacts)
4. Check indentation preserved in all code examples

**Expected:** Code blocks render with syntax highlighting, copy cleanly

---

## Phase 2: Content Accuracy & Completeness

### Test 2.1: Word Count Verification

**Description:** Verify article meets word count targets.
**Steps:**

1. Count total words in article (target: 4,000-5,000)
2. Count words in each section (verify target ranges per SPEC)
3. Check section headers don't inflate word count

**Expected:**

- Total: 4,000-5,000 words
- Section 1: 400-500 words
- Section 2: 600-700 words
- Section 3: 800-900 words
- Section 4: 1,000-1,200 words
- Section 5: 600-700 words
- Section 6: 600-700 words
- Section 7: 400-500 words
- Section 8: 500-600 words
- Section 9: 400-500 words
- Section 10: 600-700 words

### Test 2.2: Specification Compliance

**Description:** Verify article adheres to SPEC.md requirements.
**Steps:**

1. Check 10 sections present and in correct order
2. Verify all required topics covered (tables, dimensions, patterns, tools)
3. Verify no required content missing

**Expected:** All SPEC.md requirements met

### Test 2.3: Design Patterns Coverage

**Description:** Verify all 8 design patterns documented.
**Steps:**

1. Check Pattern 1: Centered Title Focus ✓
2. Check Pattern 2: Left-Aligned Content ✓
3. Check Pattern 3: Hero Image + Text Overlay ✓
4. Check Pattern 4: Dual Column ✓
5. Check Pattern 5: Badge Design (Minimal) ✓
6. Check Pattern 6: Corner Logo + Bold Background ✓
7. Check Pattern 7: Bottom Text Anchor ✓
8. Check Pattern 8: Gradient Accent Bars ✓
9. Verify each includes: description, use cases, specs, pros/cons

**Expected:** All 8 patterns documented with specifications

### Test 2.4: Company Examples Coverage

**Description:** Verify 8+ real-world examples included.
**Steps:**

1. Verify examples present for: GitHub, Stripe, Linear, Webflow, Notion, HelpScout, Unsplash
2. Verify each example includes: company name, brief description, key takeaway
3. Check examples are current and accurate

**Expected:** 7+ company examples with descriptions

### Test 2.5: Tool Comparison Accuracy

**Description:** Verify tool comparisons are accurate.
**Steps:**

1. Check all 8 tools listed: Vercel, Puppeteer, Bannerbear, Canvas, Cloudflare, Netlify, Placid, Robolly
2. Verify performance characteristics accurate
3. Verify use cases match tool capabilities
4. Check comparison table complete

**Expected:** All tools accurately described with correct specs

### Test 2.6: Specification Tables Accuracy

**Description:** Verify dimension and specification tables are correct.
**Steps:**

1. Check platform dimension table (1200×630 primary, Twitter 1200×675, etc.)
2. Verify aspect ratio calculations (1.91:1 is correct)
3. Check file size recommendations (100-200KB primary, <500KB max)
4. Verify format comparison table (JPEG, PNG, WebP trade-offs)

**Expected:** All specifications technically correct

### Test 2.7: Meta Tag Code Snippet

**Description:** Verify HTML example is correct and complete.
**Steps:**

1. Check og:image tag present and correct
2. Verify og:image:width and og:image:height present
3. Check twitter:card set to "summary_large_image"
4. Verify og:image:alt present
5. Validate all attributes spelled correctly
6. Check for typos in meta tag names

**Expected:** HTML snippet valid and complete

### Test 2.8: Checklist Completeness

**Description:** Verify best practices checklist is comprehensive.
**Steps:**

1. Count checklist items (target: 40+)
2. Verify items cover: planning, design, testing, accessibility, implementation, monitoring
3. Check all items are actionable
4. Verify no duplicate items

**Expected:** 40+ checklist items across 6 phases

### Test 2.9: Common Mistakes Coverage

**Description:** Verify all 10 common mistakes documented.
**Steps:**

1. Mistake 1: Too Much Text ✓
2. Mistake 2: Ignoring Contrast ✓
3. Mistake 3: File Size Too Large ✓
4. Mistake 4: Inconsistent Visual Style ✓
5. Mistake 5: Light Backgrounds ✓
6. Mistake 6: Ignoring Mobile Context ✓
7. Mistake 7: Missing Brand Elements ✓
8. Mistake 8: Wrong Dimensions ✓
9. Mistake 9: Unreadable Fonts ✓
10. Mistake 10: Not Testing on Platforms ✓
11. Verify each includes: problem, cause, solution, example

**Expected:** 10 mistakes with full remediation guidance

### Test 2.10: Accessibility Guidance Coverage

**Description:** Verify accessibility section is complete.
**Steps:**

1. Check WCAG AA contrast ratio mentioned (4.5:1)
2. Verify alt text guidance present
3. Check color blindness considerations documented
4. Verify testing tools listed
5. Check platform-specific accessibility notes

**Expected:** Comprehensive accessibility guidance

---

## Phase 3: Accessibility Compliance

### Test 3.1: WCAG Contrast Compliance

**Description:** Verify article discusses WCAG standards correctly.
**Steps:**

1. Confirm 4.5:1 ratio mentioned for normal text (WCAG AA)
2. Confirm 7:1 ratio mentioned for AAA level
3. Verify 3:1 ratio mentioned for large text (18pt+)
4. Check examples of compliant/non-compliant contrast provided

**Expected:** All WCAG standards correctly stated

### Test 3.2: Alt Text Guidance

**Description:** Verify alt text section is correct and actionable.
**Steps:**

1. Check alt text definition provided
2. Verify guidance on descriptive writing
3. Check character limits mentioned (≤125 chars)
4. Verify good/bad examples provided
5. Check og:image:alt meta tag explained

**Expected:** Clear alt text guidance with examples

### Test 3.3: Color Blindness Considerations

**Description:** Verify article addresses color blindness.
**Steps:**

1. Check color blindness statistics mentioned
2. Verify guidance to not rely on color alone
3. Check complementary patterns (icons, text labels) explained
4. Verify tools for testing (ColorBlind app, Coblis) mentioned

**Expected:** Color blindness guidance complete

### Test 3.4: Font Readability

**Description:** Verify typography accessibility covered.
**Steps:**

1. Check font size guidance (24px minimum body, 60px+ titles)
2. Verify font weight guidance (bold for readability)
3. Check sans-serif recommendation justified
4. Verify decorative fonts discouraged

**Expected:** Typography accessibility clear

### Test 3.5: Platform Accessibility Features

**Description:** Verify platform-specific accessibility documented.
**Steps:**

1. Check Facebook alt text support mentioned
2. Check Twitter alt text support mentioned
3. Check LinkedIn alt text support mentioned
4. Verify platform handling of text on images

**Expected:** Platform accessibility features documented

---

## Phase 4: Cross-Platform Validation

### Test 4.1: Facebook Sharing Debugger Simulation

**Description:** Simulate Facebook parsing and preview.
**Steps:**

1. Verify og:image URL would be absolute (test with example.com)
2. Check og:image:width/height match 1200/630
3. Verify og:type set to "website"
4. Check og:title and og:description present and distinct

**Expected:** Article recommends correct Facebook implementation

### Test 4.2: Twitter Card Validation

**Description:** Verify Twitter/X specifications.
**Steps:**

1. Check twitter:card = "summary_large_image" recommended
2. Verify 1200×675px dimensions mentioned for Twitter optimization
3. Check alt text importance for Twitter noted
4. Verify article doesn't recommend WebP (poor Twitter support)

**Expected:** Twitter-specific guidance correct

### Test 4.3: LinkedIn Specifications

**Description:** Verify LinkedIn requirements accurate.
**Steps:**

1. Check 1200×628px mentioned as LinkedIn dimension
2. Verify 1.91:1 aspect ratio works on LinkedIn
3. Check JPEG/PNG format recommendations
4. Verify alt text support mentioned

**Expected:** LinkedIn specifications accurate

### Test 4.4: Slack & Discord Compatibility

**Description:** Verify messaging app compatibility guidance.
**Steps:**

1. Check file size constraints for Slack mentioned (300-400KB)
2. Verify load time importance noted
3. Check format flexibility (no WebP strict requirement)
4. Verify aspect ratio flexibility on Slack/Discord

**Expected:** Messaging app guidance complete

### Test 4.5: iMessage & WhatsApp Compatibility

**Description:** Verify messaging client compatibility.
**Steps:**

1. Check WhatsApp compatibility mentioned
2. Verify iMessage support noted
3. Check file size strictness explained
4. Verify aspect ratio flexibility

**Expected:** Messaging client compatibility clear

---

## Phase 4 Continuation: Advanced Validations

### Test 4.6: Aspect Ratio Accuracy

**Description:** Verify all aspect ratio calculations correct.
**Steps:**

1. Verify 1200÷630 = 1.91:1 ✓
2. Verify 1200÷675 = 1.78:1 ✓
3. Verify 600÷315 = 1.91:1 ✓
4. Verify all ratios used in article match calculations

**Expected:** All aspect ratios mathematically correct

### Test 4.7: File Size Recommendations Realistic

**Description:** Verify file size targets are achievable.
**Steps:**

1. Check 100-150KB range reasonable for JPG 85% quality at 1200×630 ✓
2. Verify 80-120KB achievable for JPG 75% quality ✓
3. Check 200-350KB reasonable for optimized PNG ✓
4. Verify 50-100KB achievable for WebP ✓

**Expected:** File size targets realistic for formats/quality

### Test 4.8: Platform Display Consistency

**Description:** Verify article explains platform rendering correctly.
**Steps:**

1. Check Facebook full-width display explained
2. Verify Twitter inline display explained
3. Check LinkedIn thumbnail display explained
4. Verify 50% mobile scaling mentioned for all

**Expected:** Platform display behaviors accurately described

### Test 4.9: Examples Real & Specific

**Description:** Verify examples are genuine and specific.
**Steps:**

1. Verify GitHub approach (left-aligned code visuals) is accurate
2. Verify Stripe approach (bold gradients, minimal text) is accurate
3. Check all company examples represent real observed patterns
4. Verify no fabricated or generic examples

**Expected:** All examples based on observable real patterns

### Test 4.10: Tone & Voice Consistency

**Description:** Verify article maintains consistent professional tone.
**Steps:**

1. Check tone is educational, not promotional
2. Verify language is clear and accessible
3. Check for jargon (minimized, explained when used)
4. Verify no spelling/grammar errors
5. Check consistency of terminology (e.g., always "OG image" not sometimes "og-image")

**Expected:** Professional, educational, consistent tone throughout

---

## QA Report Template

Run all 16 tests and populate results below:

### Summary

- **Total Tests:** 16
- **Passed:** \_\_\_/16
- **Failed:** \_\_\_/16
- **Pass Rate:** \_\_\_%

### Phase 1 Results

| Test                | Status | Notes |
| ------------------- | ------ | ----- |
| 1.1 Markdown Syntax | ✓/✗    |       |
| 1.2 TOC Links       | ✓/✗    |       |
| 1.3 Internal Links  | ✓/✗    |       |
| 1.4 Encoding        | ✓/✗    |       |
| 1.5 Code Snippets   | ✓/✗    |       |

### Phase 2 Results

| Test                 | Status | Notes |
| -------------------- | ------ | ----- |
| 2.1 Word Count       | ✓/✗    |       |
| 2.2 Spec Compliance  | ✓/✗    |       |
| 2.3 Design Patterns  | ✓/✗    |       |
| 2.4 Company Examples | ✓/✗    |       |
| 2.5 Tool Comparison  | ✓/✗    |       |
| 2.6 Spec Tables      | ✓/✗    |       |
| 2.7 Meta Tag Code    | ✓/✗    |       |
| 2.8 Checklist        | ✓/✗    |       |
| 2.9 Common Mistakes  | ✓/✗    |       |
| 2.10 Accessibility   | ✓/✗    |       |

### Phase 3 Results

| Test                 | Status | Notes |
| -------------------- | ------ | ----- |
| 3.1 WCAG Contrast    | ✓/✗    |       |
| 3.2 Alt Text         | ✓/✗    |       |
| 3.3 Color Blindness  | ✓/✗    |       |
| 3.4 Font Readability | ✓/✗    |       |
| 3.5 Platform A11y    | ✓/✗    |       |

### Phase 4 Results

| Test                  | Status | Notes |
| --------------------- | ------ | ----- |
| 4.1 Facebook          | ✓/✗    |       |
| 4.2 Twitter           | ✓/✗    |       |
| 4.3 LinkedIn          | ✓/✗    |       |
| 4.4 Slack/Discord     | ✓/✗    |       |
| 4.5 iMessage/WhatsApp | ✓/✗    |       |
| 4.6 Aspect Ratios     | ✓/✗    |       |
| 4.7 File Sizes        | ✓/✗    |       |
| 4.8 Platform Display  | ✓/✗    |       |
| 4.9 Examples          | ✓/✗    |       |
| 4.10 Tone/Voice       | ✓/✗    |       |

### Critical Issues Found

[List any issues that block publication]

### Recommended Fixes

[Specific fixes for each issue]

### Sign-off

- [ ] All tests passed
- [ ] Critical issues resolved
- [ ] Ready for publication
