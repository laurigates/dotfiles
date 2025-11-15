#!/usr/bin/env python3
"""
Selective secret auditing script for detect-secrets.

This script allows you to mark secrets as verified based on file patterns,
enabling you to audit categories of files rather than all-or-nothing.

Usage:
    # Mark all secrets in test files as false positives
    python scripts/audit-secrets-selective.py --pattern "test_.*\\.py" --false-positive

    # Mark specific file patterns as true secrets
    python scripts/audit-secrets-selective.py --pattern "\\.env\\.example" --true-secret

    # Interactive review of secrets in specific files
    python scripts/audit-secrets-selective.py --pattern "config/.*" --interactive
"""

from detect_secrets.core import baseline
import sys
import re
import argparse


def audit_by_pattern(
    baseline_file: str,
    pattern: str,
    is_secret: bool = False,
    interactive: bool = False
):
    """
    Mark secrets matching a file pattern as verified.

    Args:
        baseline_file: Path to the baseline file
        pattern: Regex pattern to match filenames
        is_secret: True if these are real secrets, False if false positives
        interactive: If True, prompt for each secret
    """
    try:
        # Load the baseline
        print(f"📖 Loading baseline from {baseline_file}...")
        secrets_collection = baseline.load(
            baseline.load_from_file(baseline_file)
        )

        pattern_re = re.compile(pattern)
        verified_count = 0
        skipped_count = 0
        matched_files = set()

        # Iterate through all secrets
        for filename, secret in secrets_collection:
            if not pattern_re.search(filename):
                skipped_count += 1
                continue

            matched_files.add(filename)

            if interactive:
                print(f"\n📄 File: {filename}")
                print(f"   Line: {secret.line_number}")
                print(f"   Type: {secret.type}")
                response = input("   Mark as false positive? (y/n): ").lower()
                if response != 'y':
                    continue
                secret.is_secret = False
            else:
                secret.is_secret = is_secret

            secret.is_verified = True
            verified_count += 1

        # Save the updated baseline
        if verified_count > 0:
            print(f"\n💾 Saving updated baseline to {baseline_file}...")
            baseline.save_to_file(secrets_collection, baseline_file)

        # Print summary
        print("\n✅ Audit complete!")
        print(f"   Pattern: {pattern}")
        print(f"   Matched files: {len(matched_files)}")
        print(f"   Verified: {verified_count}")
        print(f"   Skipped: {skipped_count}")
        print(f"   Classification: {'true secrets' if is_secret else 'false positives'}")

        if matched_files:
            print("\n📋 Matched files:")
            for f in sorted(matched_files):
                print(f"   - {f}")

        return 0

    except FileNotFoundError:
        print(f"❌ Error: Baseline file '{baseline_file}' not found", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


def main():
    parser = argparse.ArgumentParser(
        description='Selectively audit secrets based on file patterns'
    )
    parser.add_argument(
        '--baseline',
        default='.secrets.baseline',
        help='Path to baseline file (default: .secrets.baseline)'
    )
    parser.add_argument(
        '--pattern',
        required=True,
        help='Regex pattern to match filenames'
    )
    parser.add_argument(
        '--false-positive',
        action='store_true',
        help='Mark matched secrets as false positives'
    )
    parser.add_argument(
        '--true-secret',
        action='store_true',
        help='Mark matched secrets as true secrets'
    )
    parser.add_argument(
        '--interactive',
        action='store_true',
        help='Prompt for each secret interactively'
    )

    args = parser.parse_args()

    # Validate arguments
    if args.true_secret and args.false_positive:
        print("❌ Error: Cannot specify both --true-secret and --false-positive", file=sys.stderr)
        return 1

    if not args.interactive and not (args.true_secret or args.false_positive):
        print("❌ Error: Must specify --true-secret, --false-positive, or --interactive", file=sys.stderr)
        return 1

    is_secret = args.true_secret if not args.interactive else False

    return audit_by_pattern(
        args.baseline,
        args.pattern,
        is_secret=is_secret,
        interactive=args.interactive
    )


if __name__ == '__main__':
    sys.exit(main())
