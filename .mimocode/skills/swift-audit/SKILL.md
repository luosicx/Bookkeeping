---
name: swift-audit
description: "Audit a Swift/macOS/iOS project for common code quality issues — force unwraps, logging consistency, file size, localization syntax, unused imports, and more. Produces a prioritized issue report and optionally fixes issues in-place."
---

# Swift Project Code Audit

Run a structured static analysis checklist against a Swift project. Each check is a grep-based scan that surfaces real issues, not style opinions.

## When to Use

- Before a release or PR merge
- After onboarding a new codebase
- When the user asks to "check for problems", "review the project", or "find issues"

## Inputs

- `$PROJECT_DIR` — root of the Swift project (default: current working directory)

## Checks (run all, report each category)

### C01 — Force Unwraps (`as!`, `try!`, `!` on optionals)

```bash
echo "=== C01: Force unwraps ==="
grep -rn ' as! \| try! ' --include="*.swift" "$PROJECT_DIR" | grep -v '//\|"\|swiftlint\|\.build' | head -30
grep -rn '!\s*$\|first!\|last!' --include="*.swift" "$PROJECT_DIR" | grep -v '//\|"\|Info.plist\|fatalError\|\.swiftlint\|\.build' | head -20
```

### C02 — `print()` Calls (should use Logger)

```bash
echo "=== C02: print() calls ==="
grep -rn 'print(' --include="*.swift" "$PROJECT_DIR" | grep -v 'Logger\|import\|//\|swiftlint\|\.build\|MARK:' | head -20
```

### C03 — Logging Prefix Consistency

```bash
echo "=== C03: Logging prefix consistency ==="
grep -roh 'logToFile("\[[^]]*\]' --include="*.swift" "$PROJECT_DIR" | sort | uniq -c | sort -rn
grep -roh 'logToFile("[A-Za-z]*:' --include="*.swift" "$PROJECT_DIR" | sort | uniq -c | sort -rn
```

### C04 — Large Files (>300 lines)

```bash
echo "=== C04: Files > 300 lines ==="
find "$PROJECT_DIR" -name "*.swift" -not -path "*/.build/*" -exec wc -l {} \; | sort -rn | awk '$1 > 300 {print $0}'
```

### C05 — Non-Final Classes

```bash
echo "=== C05: Non-final classes ==="
grep -rn '^public class\|^class' --include="*.swift" "$PROJECT_DIR" | grep -v 'final\|protocol\|swiftlint\|\.build\|Localizable' | head -20
```

### C06 — Hardcoded Identifiers / URLs

```bash
echo "=== C06: Hardcoded identifiers ==="
grep -rn '"com\.\|https://example\.\|http://localhost' --include="*.swift" "$PROJECT_DIR" | grep -v '//\|swiftlint\|\.build\|Test' | head -20
```

### C07 — Localization `.strings` Syntax

```bash
echo "=== C07: Localization syntax ==="
find "$PROJECT_DIR" -name "*.strings" -exec grep -Pn '^\s*$|[^";]\s*$' {} \; 2>/dev/null | grep -v '^--$\|//' | head -20
# Also check for orphan lines (lines not matching "key" = "value"; pattern)
find "$PROJECT_DIR" -name "Localizable.strings" -exec grep -Pn '^[^"/].*[^;]\s*$' {} \; 2>/dev/null | head -20
```

### C08 — Duplicate Code Patterns

```bash
echo "=== C08: Duplicate patterns (NSSavePanel, etc.) ==="
grep -rn 'NSSavePanel\|\.runModal\|allowedContentTypes' --include="*.swift" "$PROJECT_DIR" -l 2>/dev/null
```

### C09 — Unused Imports

```bash
echo "=== C09: Potentially unused imports ==="
grep -rn 'import.*os\.log\|import.*Logger' --include="*.swift" "$PROJECT_DIR" | grep -v 'Logger.swift' | head -10
```

### C10 — Empty Catch Blocks

```bash
echo "=== C10: Empty catch blocks ==="
grep -rn 'catch\s*{' --include="*.swift" "$PROJECT_DIR" -A1 | grep -v 'catch\|--\|{' | grep '^\s*}' | head -10
```

## Output Format

After running all checks, produce a summary table:

```
| ID | Category | Severity | Count | Files |
|----|----------|----------|-------|-------|
| C01 | Force unwraps | HIGH | 3 | Foo.swift, Bar.swift |
| C02 | print() calls | MEDIUM | 7 | ... |
| ... | ... | ... | ... | ... |
```

Then for each non-zero category:
1. **Root cause** — why the issue exists
2. **Fix pattern** — concrete code transformation
3. **Affected files** — list with line numbers

## Optional: Auto-Fix

If the user asks to fix issues, apply fixes category by category, verifying with `xcodebuild` after each batch. Commit after each logical group of fixes.

## Notes

- All checks use `grep` only — no external linters required
- Exclude `.build/`, `Pods/`, `Carthage/`, and `DerivedData/` directories
- Adapt checks to the project's actual logging API (check `Logger.swift` or equivalent first)
- For XcodeGen projects, also check `project.yml` for hardcoded bundle identifiers
