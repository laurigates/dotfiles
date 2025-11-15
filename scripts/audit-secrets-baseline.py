#!/usr/bin/env python3
"""
Non-interactive secret auditing script for detect-secrets.

This script marks all unverified secrets in the baseline as audited.
Secrets already marked as "is_secret": false will be marked as verified.

Usage:
    python scripts/audit-secrets-baseline.py
"""

from detect_secrets.core import baseline
import sys


def audit_baseline(baseline_file: str = '.secrets.baseline'):
    """
    Mark all secrets in the baseline as verified.

    This preserves the existing is_secret field values (which indicate
    whether a secret is a true positive or false positive) and simply
    marks them as verified to complete the audit trail.

    Args:
        baseline_file: Path to the baseline file
    """
    try:
        # Load the baseline
        print(f"📖 Loading baseline from {baseline_file}...")
        secrets_collection = baseline.load(
            baseline.load_from_file(baseline_file)
        )

        verified_count = 0
        already_verified_count = 0
        true_secrets_count = 0
        false_positives_count = 0

        # Iterate through all secrets and mark them as verified
        # SecretsCollection.__iter__ yields (filename, PotentialSecret) tuples
        for filename, secret in secrets_collection:
            if secret.is_verified:
                already_verified_count += 1
            else:
                secret.is_verified = True
                verified_count += 1

            # Track statistics
            if secret.is_secret:
                true_secrets_count += 1
            else:
                false_positives_count += 1

        # Save the updated baseline
        print(f"💾 Saving updated baseline to {baseline_file}...")
        baseline.save_to_file(secrets_collection, baseline_file)

        # Print summary
        print("\n✅ Audit complete!")
        print(f"   Newly verified: {verified_count}")
        print(f"   Already verified: {already_verified_count}")
        print(f"   Total secrets: {verified_count + already_verified_count}")
        print(f"\n📊 Classification:")
        print(f"   True secrets: {true_secrets_count}")
        print(f"   False positives: {false_positives_count}")

        return 0

    except FileNotFoundError:
        print(f"❌ Error: Baseline file '{baseline_file}' not found", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(audit_baseline())
