#!/usr/bin/env python3
"""
Deploy Medical Vocabularies to AWS Transcribe
Handles vocabulary file upload with proper AWS API formatting
"""

import os
import sys
import json
import time
import boto3
from pathlib import Path
from datetime import datetime

def create_transcribe_client(region, profile=None):
    """Create AWS Transcribe client"""
    if profile:
        session = boto3.Session(profile_name=profile)
    else:
        session = boto3.Session()
    return session.client('transcribe', region_name=region)

def read_vocabulary_file(filepath):
    """Read vocabulary file and parse entries"""
    entries = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                entries.append(line)
        return entries
    except Exception as e:
        print(f"❌ Error reading file {filepath}: {e}")
        return None

def create_vocabulary(client, vocab_name, language_code, entries, region, log_file=None):
    """Create vocabulary in AWS Transcribe"""
    try:
        # Check if vocabulary already exists
        try:
            response = client.get_vocabulary(VocabularyName=vocab_name)
            print(f"⚠️  Vocabulary '{vocab_name}' already exists. Skipping...")
            if log_file:
                log_file.write(f"⚠️  Vocabulary '{vocab_name}' already exists.\n")
            return True
        except client.exceptions.BadRequestException:
            # Vocabulary doesn't exist, proceed to create
            pass

        print(f"Creating vocabulary: {vocab_name} (language: {language_code}, {len(entries)} terms)...")

        response = client.create_vocabulary(
            VocabularyName=vocab_name,
            LanguageCode=language_code,
            Phrases=entries
        )

        print(f"✅ Created vocabulary: {vocab_name}")
        if log_file:
            log_file.write(f"✅ Created vocabulary: {vocab_name}\n")
        return True

    except Exception as e:
        print(f"❌ Failed to create vocabulary: {vocab_name}")
        print(f"   Error: {str(e)}")
        if log_file:
            log_file.write(f"❌ Failed to create vocabulary: {vocab_name} - {str(e)}\n")
        return False

def wait_for_vocabulary(client, vocab_name, max_wait=300, log_file=None):
    """Wait for vocabulary to reach READY state"""
    elapsed = 0
    print(f"Waiting for vocabulary '{vocab_name}' to be ready...")

    while elapsed < max_wait:
        try:
            response = client.get_vocabulary(VocabularyName=vocab_name)
            status = response['VocabularyState']

            if status == 'READY':
                print(f"✅ Vocabulary '{vocab_name}' is READY")
                if log_file:
                    log_file.write(f"✅ Vocabulary '{vocab_name}' is READY\n")
                return True
            elif status == 'FAILED':
                print(f"❌ Vocabulary '{vocab_name}' FAILED")
                print(f"   Reason: {response.get('FailureReason', 'Unknown')}")
                if log_file:
                    log_file.write(f"❌ Vocabulary '{vocab_name}' FAILED\n")
                return False
            else:
                print(f"⏳ Status: {status} (waiting...)")

            time.sleep(5)
            elapsed += 5

        except Exception as e:
            print(f"⏳ Checking status (waiting...)")
            time.sleep(5)
            elapsed += 5

    print(f"⚠️  Timeout waiting for vocabulary '{vocab_name}'")
    if log_file:
        log_file.write(f"⚠️  Timeout waiting for vocabulary '{vocab_name}'\n")
    return False

def main():
    region = sys.argv[1] if len(sys.argv) > 1 else 'eu-central-1'
    profile = sys.argv[2] if len(sys.argv) > 2 else None

    vocab_dir = Path('medical-vocabularies')
    log_filename = f"vocab-deployment-{datetime.now().strftime('%Y%m%d-%H%M%S')}.log"

    print("=" * 50)
    print("Medical Vocabulary Deployment")
    print("=" * 50)
    print(f"Region: {region}")
    print(f"Profile: {profile or 'default'}")
    print(f"Vocabulary Directory: {vocab_dir}")
    print(f"Log File: {log_filename}")
    print("=" * 50)
    print()

    # Verify vocabulary directory exists
    if not vocab_dir.exists():
        print(f"❌ Vocabulary directory '{vocab_dir}' not found.")
        sys.exit(1)

    # Initialize AWS client
    try:
        client = create_transcribe_client(region, profile)
        print("✅ Connected to AWS Transcribe\n")
    except Exception as e:
        print(f"❌ Failed to connect to AWS: {e}")
        sys.exit(1)

    # Open log file
    with open(log_filename, 'w') as log_file:
        log_file.write(f"Medical Vocabulary Deployment - {datetime.now()}\n")
        log_file.write(f"Region: {region}\n")
        log_file.write(f"Profile: {profile or 'default'}\n\n")

        # Define vocabularies to deploy
        vocabularies = [
            ('medical-vocabularies/medzen-medical-vocab-en.txt', 'medzen-medical-vocab-en', 'en-US'),
            ('medical-vocabularies/medzen-medical-vocab-fr.txt', 'medzen-medical-vocab-fr', 'fr-FR'),
            ('medical-vocabularies/medzen-medical-vocab-sw.txt', 'medzen-medical-vocab-sw', 'sw-KE'),
            ('medical-vocabularies/medzen-medical-vocab-zu.txt', 'medzen-medical-vocab-zu', 'zu-ZA'),
            ('medical-vocabularies/medzen-medical-vocab-ha.txt', 'medzen-medical-vocab-ha', 'ha-NG'),
            ('medical-vocabularies/medzen-medical-vocab-yo-fallback-en.txt', 'medzen-medical-vocab-yo-fallback-en', 'en-US'),
            ('medical-vocabularies/medzen-medical-vocab-ig-fallback-en.txt', 'medzen-medical-vocab-ig-fallback-en', 'en-US'),
            ('medical-vocabularies/medzen-medical-vocab-pcm-fallback-en.txt', 'medzen-medical-vocab-pcm-fallback-en', 'en-US'),
            ('medical-vocabularies/medzen-medical-vocab-ln-fallback-fr.txt', 'medzen-medical-vocab-ln-fallback-fr', 'fr-FR'),
            ('medical-vocabularies/medzen-medical-vocab-kg-fallback-fr.txt', 'medzen-medical-vocab-kg-fallback-fr', 'fr-FR'),
        ]

        # Deploy vocabularies
        successful = []
        failed = []

        for vocab_file, vocab_name, language_code in vocabularies:
            if not Path(vocab_file).exists():
                print(f"⊘ Skipping {vocab_name} (file not found)")
                log_file.write(f"⊘ Skipped {vocab_name} (file not found)\n")
                continue

            entries = read_vocabulary_file(vocab_file)
            if entries is None:
                failed.append(vocab_name)
                continue

            if create_vocabulary(client, vocab_name, language_code, entries, region, log_file):
                successful.append((vocab_name, len(entries)))
            else:
                failed.append(vocab_name)

        # Wait for critical vocabularies
        print("\n=== Waiting for Critical Vocabularies to be Ready ===\n")
        log_file.write("\nWaiting for vocabularies to be ready...\n")

        for vocab_name, _ in successful:
            if vocab_name in ['medzen-medical-vocab-en', 'medzen-medical-vocab-fr']:
                wait_for_vocabulary(client, vocab_name, log_file=log_file)

        # Print summary
        print("\n" + "=" * 50)
        print("Deployment Summary")
        print("=" * 50)
        print(f"\n✅ Successfully created: {len(successful)} vocabularies")
        for vocab_name, term_count in successful:
            print(f"   • {vocab_name} ({term_count} terms)")

        if failed:
            print(f"\n❌ Failed: {len(failed)} vocabularies")
            for vocab_name in failed:
                print(f"   • {vocab_name}")

        print(f"\nLog file: {log_filename}")

        print("\nNext Steps:")
        print("1. Verify all vocabularies are READY in AWS Transcribe:")
        print(f"   aws transcribe list-vocabularies --region {region}")
        print("\n2. Deploy the updated edge function:")
        print("   npx supabase functions deploy start-medical-transcription")
        print("\n3. Apply the database migration:")
        print("   npx supabase migration up")
        print("\n4. Test medical transcription in different languages")
        print("=" * 50)

        # Log summary
        log_file.write(f"\n✅ Successfully created: {len(successful)} vocabularies\n")
        for vocab_name, term_count in successful:
            log_file.write(f"   • {vocab_name} ({term_count} terms)\n")

        if failed:
            log_file.write(f"\n❌ Failed: {len(failed)} vocabularies\n")
            for vocab_name in failed:
                log_file.write(f"   • {vocab_name}\n")

if __name__ == '__main__':
    main()
