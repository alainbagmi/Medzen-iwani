#!/usr/bin/env python3
"""
Reformat medical vocabulary files for AWS Transcribe compatibility.

AWS Transcribe has strict character validation:
- Rejects spaces in terms (must use hyphens instead: "type-1-diabetes" not "type 1 diabetes")
- May reject or accept numbers (we'll keep them for medical accuracy)
- Rejects most special characters

This script reformats all vocabulary files to be AWS-compatible.
"""

import os
from pathlib import Path

def format_for_aws_transcribe(term):
    """
    Format a term to be AWS Transcribe compatible.

    Rules:
    - Replace spaces with hyphens
    - Keep numbers (medical terms need them: "type-1-diabetes")
    - Remove leading/trailing whitespace
    - Skip empty lines and comments
    """
    term = term.strip()
    if not term or term.startswith('#'):
        return None

    # Replace spaces with hyphens
    term = term.replace(' ', '-')

    # Remove any trailing commas (from previous format)
    term = term.rstrip(',')

    # Remove any trailing numbers after commas (boost weights)
    if ',' in term:
        term = term.split(',')[0].strip()

    # Replace spaces again (in case there were spaces after splitting)
    term = term.replace(' ', '-')

    return term if term else None

def process_vocabulary_file(input_path, output_path):
    """
    Process a vocabulary file and save reformatted version.

    Returns:
        tuple: (num_terms, num_modified) - total terms and how many were modified
    """
    terms = []
    modified_count = 0
    original_count = 0

    # Read input file
    with open(input_path, 'r', encoding='utf-8') as f:
        for line in f:
            formatted = format_for_aws_transcribe(line)
            if formatted:
                original_count += 1
                # Check if it was modified (has hyphens where spaces were)
                if '-' in formatted and ' ' not in line:
                    # This is a multi-word term converted to hyphens
                    modified_count += 1
                elif '-' in formatted and ' ' in line:
                    # Already had spaces, now converted
                    modified_count += 1
                terms.append(formatted)

    # Write output file
    with open(output_path, 'w', encoding='utf-8') as f:
        for term in sorted(set(terms)):  # Deduplicate and sort
            f.write(term + '\n')

    return len(set(terms)), modified_count

def main():
    """Main function to reformat all vocabulary files."""

    vocab_dir = Path('/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/medical-vocabularies')

    # List of vocabulary files to reformat
    vocab_files = [
        'medzen-medical-vocab-en.txt',
        'medzen-medical-vocab-fr.txt',
        'medzen-medical-vocab-sw.txt',
        'medzen-medical-vocab-zu.txt',
        'medzen-medical-vocab-ha.txt',
        'medzen-medical-vocab-yo-fallback-en.txt',
        'medzen-medical-vocab-ig-fallback-en.txt',
        'medzen-medical-vocab-pcm-fallback-en.txt',
        'medzen-medical-vocab-ln-fallback-fr.txt',
        'medzen-medical-vocab-kg-fallback-fr.txt',
    ]

    print("🔄 Reformatting medical vocabulary files for AWS Transcribe compatibility...\n")
    print("AWS Transcribe Rules:")
    print("  • Spaces → Hyphens (type 1 diabetes → type-1-diabetes)")
    print("  • Deduplicate and sort terms")
    print("  • Remove comments and empty lines\n")

    total_files = 0
    total_terms = 0
    total_modified = 0

    for vocab_file in vocab_files:
        input_path = vocab_dir / vocab_file

        if not input_path.exists():
            print(f"⊘ File not found: {vocab_file}")
            continue

        # Process the file
        num_terms, num_modified = process_vocabulary_file(input_path, input_path)

        total_files += 1
        total_terms += num_terms
        total_modified += num_modified

        print(f"✅ {vocab_file}")
        print(f"   → {num_terms} unique terms (modified: {num_modified})")

    print(f"\n📊 Summary:")
    print(f"   Files processed: {total_files}")
    print(f"   Total unique terms: {total_terms}")
    print(f"   Terms with spaces converted: {total_modified}")
    print(f"\n✓ All vocabulary files reformatted and ready for AWS deployment!")

if __name__ == '__main__':
    main()
