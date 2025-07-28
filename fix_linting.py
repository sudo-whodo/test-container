#!/usr/bin/env python3
"""
Script to help fix remaining Python linting issues
"""

import os
import subprocess
import sys

def run_pylint():
    """Run pylint and return the output"""
    try:
        result = subprocess.run([
            'pylint', '--rcfile=.config/.pylintrc',
            'app/app.py', 'tests/test_http_endpoints.py'
        ], capture_output=True, text=True, check=False)
        return result.stdout
    except FileNotFoundError:
        print("Error: pylint not found. Install with: pipx install pylint")
        return None

def analyze_issues(pylint_output):
    """Analyze pylint output and categorize issues"""
    issues = {
        'import_errors': [],
        'line_too_long': [],
        'f_string_issues': [],
        'broad_exceptions': [],
        'complexity_issues': [],
        'other': []
    }

    lines = pylint_output.split('\n')
    for line in lines:
        if 'E0401: Unable to import' in line:
            issues['import_errors'].append(line)
        elif 'C0301: Line too long' in line:
            issues['line_too_long'].append(line)
        elif ('W1309: Using an f-string that does not have any interpolated variables'
              in line):
            issues['f_string_issues'].append(line)
        elif 'W0718: Catching too general exception Exception' in line:
            issues['broad_exceptions'].append(line)
        elif any(x in line for x in ['R0913:', 'R0914:', 'R0912:',
                                     'R0915:', 'R0911:']):
            issues['complexity_issues'].append(line)
        elif line.strip() and not line.startswith('*') and not line.startswith('-'):
            issues['other'].append(line)

    return issues

def print_analysis(issues):
    """Print analysis of issues with suggestions"""
    print("🔍 PYTHON LINTING ISSUES ANALYSIS")
    print("=" * 50)

    if issues['import_errors']:
        print("\n📦 IMPORT ERRORS (Can be ignored in CI):")
        print("These are expected since dependencies aren't installed locally.")
        for issue in issues['import_errors']:
            print(f"  • {issue}")

    if issues['line_too_long']:
        print("\n📏 LINES TOO LONG:")
        print("Fix by breaking long lines or using line continuation.")
        for issue in issues['line_too_long']:
            print(f"  • {issue}")

    if issues['f_string_issues']:
        print("\n🔤 F-STRING ISSUES:")
        print("Replace f-strings without variables with regular strings.")
        for issue in issues['f_string_issues']:
            print(f"  • {issue}")

    if issues['broad_exceptions']:
        print("\n⚠️  BROAD EXCEPTION CATCHING:")
        print("Consider catching more specific exceptions.")
        for issue in issues['broad_exceptions']:
            print(f"  • {issue}")

    if issues['complexity_issues']:
        print("\n🧩 COMPLEXITY ISSUES:")
        print("Consider refactoring to reduce complexity.")
        for issue in issues['complexity_issues']:
            print(f"  • {issue}")

    if issues['other']:
        print("\n🔧 OTHER ISSUES:")
        for issue in issues['other']:
            print(f"  • {issue}")

def suggest_fixes():
    """Suggest specific fixes"""
    print("\n💡 SUGGESTED FIXES:")
    print("=" * 50)

    print("\n1. For line length issues:")
    print("   - Break long lines using parentheses")
    print("   - Use line continuation with \\")
    print("   - Consider shorter variable names")

    print("\n2. For f-string issues:")
    print("   - Replace f'text' with 'text' when no variables")
    print("   - Example: f'Hello' → 'Hello'")

    print("\n3. For complexity issues:")
    print("   - Break large functions into smaller ones")
    print("   - Use helper functions")
    print("   - Consider using configuration to reduce parameters")

    print("\n4. For broad exceptions:")
    print("   - Catch specific exceptions like ValueError, TypeError")
    print("   - Use Exception only when necessary")

    print("\n5. To disable specific warnings (if needed):")
    print("   - Add # pylint: disable=warning-name at end of line")
    print("   - Or add to .config/.pylintrc disable list")

def main():
    """Main function"""
    print("🐍 Python Linting Issue Analyzer")
    print("=" * 40)

    if not os.path.exists('.config/.pylintrc'):
        print("Error: .config/.pylintrc not found")
        return 1

    print("Running pylint...")
    output = run_pylint()

    if output is None:
        return 1

    if "Your code has been rated at" in output:
        score_line = [line for line in output.split('\n') if "Your code has been rated at" in line][0]
        print(f"\n📊 Current Score: {score_line}")

    issues = analyze_issues(output)
    print_analysis(issues)
    suggest_fixes()

    print("\n🎯 QUICK WINS:")
    print("- Fix f-string issues (easy)")
    print("- Break long lines (medium)")
    print("- Import errors can be ignored in CI")

    return 0

if __name__ == "__main__":
    sys.exit(main())
