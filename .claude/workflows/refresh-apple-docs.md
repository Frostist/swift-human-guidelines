---
description: Refresh Apple developer documentation reference files from developer.apple.com
---

# Refresh Apple Developer Documentation

Fetches the latest content from Apple's official documentation and updates the reference markdown files in `references/`. Run this after each WWDC or when Apple releases a major OS update.

## Before You Start

- Ensure you have internet access to developer.apple.com
- The workflow updates files in-place — commit the current state first if you want a clean diff
- Some DocC JSON files are large; focus on the top-level framework index + specific changed symbols

---

## Step 1 — Fetch Human Interface Guidelines

Use `read_url_content` on the following URLs and update `references/human-interface-guidelines.md` with any new design system guidance, updated component rules, or new platform patterns:

- `https://developer.apple.com/design/human-interface-guidelines/`
- `https://developer.apple.com/design/human-interface-guidelines/components`

Focus on: new materials, navigation pattern changes, updated accessibility requirements.

---

## Step 2 — Fetch SwiftUI Framework Index

Use `read_url_content` on:

- `https://developer.apple.com/tutorials/data/documentation/swiftui.json`

Scan for new top-level symbols added since last refresh. For any new symbols, fetch:
- `https://developer.apple.com/tutorials/data/documentation/swiftui/{symbolname}.json`

Update `references/swiftui-best-practices.md` with verified API signatures, new modifiers, deprecated patterns.

---

## Step 3 — Fetch Foundation Models API (⚠️ High Priority)

Use `read_url_content` on:

- `https://developer.apple.com/documentation/foundationmodels`
- `https://developer.apple.com/tutorials/data/documentation/foundationmodels.json`

Then fetch any changed symbol pages (e.g., `LanguageModelSession`, `Prompt`, `GenerationOptions`).

Update `references/foundation-models-api.md` — **replace all code examples with verified, API-accurate code from the live docs**. This file is the highest risk for stale/speculative code.

---

## Step 4 — Fetch BackgroundTasks (BGContinuedProcessingTask)

Use `read_url_content` on:

- `https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtask`
- `https://developer.apple.com/tutorials/data/documentation/backgroundtasks.json`

Update `references/background-processing-ios26.md` with any changes to task registration, execution time limits, or GPU access APIs.

---

## Step 5 — Fetch Translation Framework

Use `read_url_content` on:

- `https://developer.apple.com/documentation/translation`
- `https://developer.apple.com/tutorials/data/documentation/translation.json`

Update `references/call-translation-api.md` with verified `TranslationSession` API, supported language pairs, and any new entitlement requirements.

---

## Step 6 — Fetch Swift Synchronization Library

Use `read_url_content` on:

- `https://developer.apple.com/documentation/synchronization`
- `https://developer.apple.com/tutorials/data/documentation/synchronization/atomic.json`
- `https://developer.apple.com/tutorials/data/documentation/synchronization/mutex.json`

Update `references/swift-synchronization.md` with verified `Atomic` and `Mutex` signatures.

---

## Step 7 — Check Swift Language Updates

Use `read_url_content` on:

- `https://www.swift.org/swift-evolution/` — scan for newly accepted proposals
- `https://www.swift.org/blog/` — check for Swift release announcements

Update `references/swift-language-features.md` with any new language features or deprecations.

---

## Step 8 — Check WWDC for New Sessions

Use `read_url_content` on:

- `https://developer.apple.com/videos/wwdc2025/`

Scan the session list for any new APIs not yet covered by the reference files. If new frameworks are announced, create a new `references/{framework}.md` file with the Live Sources block and initial documentation.

---

## Step 9 — Update README Version

After completing the refresh:

1. Update `README.md` — bump the version header and add a "Last Refreshed" date
2. Update `SKILL.md` description frontmatter if new platforms or frameworks were added
3. Commit with a message like: `docs: refresh Apple developer docs — {date}`
