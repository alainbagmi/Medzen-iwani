#!/usr/bin/env python3
"""
Delete failed vocabularies from AWS Transcribe and redeploy reformatted versions.
"""

import boto3
import time
import sys
from pathlib import Path

def get_transcribe_client(region_name='eu-central-1'):
    """Create AWS Transcribe client."""
    return boto3.client('transcribe', region_name=region_name)

def delete_vocabulary(client, vocab_name):
    """Delete a vocabulary from AWS Transcribe."""
    try:
        client.delete_vocabulary(VocabularyName=vocab_name)
        print(f"✅ Deleted: {vocab_name}")
        return True
    except client.exceptions.BadRequestException as e:
        if 'does not exist' in str(e):
            print(f"ℹ️  Already deleted: {vocab_name}")
            return True
        else:
            print(f"❌ Failed to delete {vocab_name}: {str(e)}")
            return False
    except Exception as e:
        print(f"❌ Error deleting {vocab_name}: {str(e)}")
        return False

def read_vocabulary_file(filepath):
    """Read vocabulary terms from file."""
    entries = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    entries.append(line)
        return entries
    except Exception as e:
        print(f"❌ Error reading {filepath}: {str(e)}")
        return []

def create_vocabulary(client, vocab_name, language_code, entries):
    """Create a vocabulary in AWS Transcribe."""
    try:
        response = client.create_vocabulary(
            VocabularyName=vocab_name,
            LanguageCode=language_code,
            Phrases=entries
        )
        print(f"✅ Created vocabulary: {vocab_name} ({len(entries)} terms)")
        return True
    except Exception as e:
        print(f"❌ Failed to create {vocab_name}: {str(e)}")
        return False

def wait_for_vocabulary_ready(client, vocab_name, max_wait_seconds=300):
    """Wait for vocabulary to reach READY state."""
    elapsed = 0
    check_interval = 5

    while elapsed < max_wait_seconds:
        try:
            response = client.get_vocabulary(VocabularyName=vocab_name)
            status = response['VocabularyState']

            if status == 'READY':
                print(f"   ✓ Status: READY")
                return True
            elif status == 'FAILED':
                reason = response.get('FailureReason', 'Unknown')
                print(f"   ✗ Status: FAILED - {reason}")
                return False
            else:
                print(f"   ⏳ Status: {status}... ({elapsed}s)", end='\r')

            time.sleep(check_interval)
            elapsed += check_interval

        except Exception as e:
            print(f"   ❌ Error checking status: {str(e)}")
            return False

    print(f"   ❌ Timeout waiting for READY (>{max_wait_seconds}s)")
    return False

def main():
    """Main cleanup and redeploy function."""

    region = 'eu-central-1'
    vocab_dir = Path('/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/medical-vocabularies')

    # Vocabulary configuration
    vocabularies = [
        {
            'name': 'medzen-medical-vocab-en',
            'language': 'en-US',
            'file': 'medzen-medical-vocab-en.txt',
        },
        {
            'name': 'medzen-medical-vocab-fr',
            'language': 'fr-FR',
            'file': 'medzen-medical-vocab-fr.txt',
        },
        {
            'name': 'medzen-medical-vocab-sw',
            'language': 'sw-KE',
            'file': 'medzen-medical-vocab-sw.txt',
        },
        {
            'name': 'medzen-medical-vocab-zu',
            'language': 'zu-ZA',
            'file': 'medzen-medical-vocab-zu.txt',
        },
        {
            'name': 'medzen-medical-vocab-ha',
            'language': 'ha-NG',
            'file': 'medzen-medical-vocab-ha.txt',
        },
        {
            'name': 'medzen-medical-vocab-yo-fallback-en',
            'language': 'en-US',
            'file': 'medzen-medical-vocab-yo-fallback-en.txt',
        },
        {
            'name': 'medzen-medical-vocab-ig-fallback-en',
            'language': 'en-US',
            'file': 'medzen-medical-vocab-ig-fallback-en.txt',
        },
        {
            'name': 'medzen-medical-vocab-pcm-fallback-en',
            'language': 'en-US',
            'file': 'medzen-medical-vocab-pcm-fallback-en.txt',
        },
        {
            'name': 'medzen-medical-vocab-ln-fallback-fr',
            'language': 'fr-FR',
            'file': 'medzen-medical-vocab-ln-fallback-fr.txt',
        },
        {
            'name': 'medzen-medical-vocab-kg-fallback-fr',
            'language': 'fr-FR',
            'file': 'medzen-medical-vocab-kg-fallback-fr.txt',
        },
    ]

    try:
        client = get_transcribe_client(region)
        print(f"✓ Connected to AWS Transcribe (region: {region})\n")
    except Exception as e:
        print(f"❌ Failed to connect to AWS: {str(e)}")
        sys.exit(1)

    # Phase 1: Delete failed vocabularies
    print("=" * 70)
    print("PHASE 1: Deleting failed vocabularies from AWS Transcribe")
    print("=" * 70)

    for vocab in vocabularies:
        delete_vocabulary(client, vocab['name'])
        time.sleep(1)  # Rate limiting

    print("\n✓ Cleanup complete!\n")

    # Phase 2: Redeploy with reformatted vocabularies
    print("=" * 70)
    print("PHASE 2: Redeploying reformatted vocabularies")
    print("=" * 70)

    successful = 0
    failed = 0

    for vocab in vocabularies:
        vocab_file_path = vocab_dir / vocab['file']

        if not vocab_file_path.exists():
            print(f"❌ File not found: {vocab['file']}")
            failed += 1
            continue

        # Read terms
        terms = read_vocabulary_file(vocab_file_path)
        if not terms:
            print(f"❌ No terms found in {vocab['file']}")
            failed += 1
            continue

        # Create vocabulary
        if create_vocabulary(client, vocab['name'], vocab['language'], terms):
            successful += 1
        else:
            failed += 1
            continue

        time.sleep(1)  # Rate limiting

    print(f"\n✓ Deployment complete! ({successful} created, {failed} failed)\n")

    # Phase 3: Wait for all vocabularies to be ready
    print("=" * 70)
    print("PHASE 3: Waiting for vocabularies to reach READY status")
    print("=" * 70)

    ready_count = 0
    failed_count = 0

    for vocab in vocabularies:
        print(f"\n{vocab['name']}:")
        if wait_for_vocabulary_ready(client, vocab['name']):
            ready_count += 1
        else:
            failed_count += 1

    print("\n" + "=" * 70)
    print("DEPLOYMENT SUMMARY")
    print("=" * 70)
    print(f"✅ Ready: {ready_count}/{len(vocabularies)}")
    print(f"❌ Failed: {failed_count}/{len(vocabularies)}")

    if failed_count == 0:
        print("\n🎉 SUCCESS! All vocabularies are ready for medical transcription!")
    else:
        print(f"\n⚠️  {failed_count} vocabularies still have issues. Review AWS logs.")

if __name__ == '__main__':
    main()
