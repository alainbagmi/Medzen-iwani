#!/usr/bin/env python3
"""
Ultra-clean medical vocabulary files for AWS Transcribe compatibility.

AWS Transcribe strict validation rules:
- Rejects numbers (0-9) - even in compound terms like "type-4-diabetes"
- Rejects accented characters (é, è, ê, ü, ñ, etc.)
- Rejects special symbols (%, &, @, #, *, etc.)
- Only allows: a-z, A-Z, hyphens (-), periods (.), apostrophes (')

This script removes/normalizes all problematic characters.
"""

import unicodedata
from pathlib import Path
import re

def remove_accents(text):
    """
    Remove accented characters and decompose Unicode.
    Converts "café" to "cafe", "é" to "e", etc.
    """
    # Normalize to NFD (decomposed form)
    nfd = unicodedata.normalize('NFD', text)
    # Filter out combining marks (accents)
    return ''.join(char for char in nfd if unicodedata.category(char) != 'Mn')

def ultra_clean_term(term):
    """
    Ultra-clean a term to be AWS Transcribe compatible.

    Rules (in order):
    1. Remove accents (é → e, ñ → n, etc.)
    2. Remove all numbers (type-4-diabetes → type-diabetes)
    3. Remove special characters except hyphens, periods, apostrophes
    4. Collapse multiple hyphens to single hyphen
    5. Remove leading/trailing hyphens, periods
    6. Skip empty terms and comments
    """
    term = term.strip()
    if not term or term.startswith('#'):
        return None

    # Remove accents and normalize Unicode
    term = remove_accents(term)

    # Remove all numbers (0-9)
    term = re.sub(r'[0-9]', '', term)

    # Remove special characters except hyphens, periods, apostrophes
    # Keep: a-z, A-Z, -, ., '
    term = re.sub(r"[^a-zA-Z\-\.'\s]", '', term)

    # Replace spaces with hyphens
    term = re.sub(r'\s+', '-', term)

    # Collapse multiple hyphens to single
    term = re.sub(r'-+', '-', term)

    # Remove leading/trailing hyphens and periods
    term = term.strip('-').strip('.')

    return term if term else None

def process_vocabulary_file(input_path, output_path):
    """
    Process a vocabulary file with ultra-cleaning.

    Returns:
        tuple: (unique_terms_count, removed_duplicates_count)
    """
    all_terms = []
    cleaned_count = 0

    # Read and clean
    with open(input_path, 'r', encoding='utf-8') as f:
        for line in f:
            cleaned = ultra_clean_term(line)
            if cleaned:
                all_terms.append(cleaned)
                cleaned_count += 1

    # Deduplicate and sort
    unique_terms = sorted(set(all_terms))
    removed_dups = len(all_terms) - len(unique_terms)

    # Write output
    with open(output_path, 'w', encoding='utf-8') as f:
        for term in unique_terms:
            f.write(term + '\n')

    return len(unique_terms), removed_dups

def main():
    """Main function to ultra-clean all vocabulary files."""

    vocab_dir = Path('/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/medical-vocabularies')

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

    print("🧹 Ultra-cleaning medical vocabulary files for AWS Transcribe...\n")
    print("Cleaning rules applied:")
    print("  • Remove accents: é→e, ñ→n, ü→u, etc.")
    print("  • Remove all numbers: type-4-diabetes → type-diabetes")
    print("  • Remove special chars (except: - . ')")
    print("  • Deduplicate and sort\n")

    total_unique = 0
    total_removed_dups = 0
    total_files = 0

    for vocab_file in vocab_files:
        input_path = vocab_dir / vocab_file

        if not input_path.exists():
            print(f"⊘ File not found: {vocab_file}")
            continue

        unique, removed_dups = process_vocabulary_file(input_path, input_path)

        total_files += 1
        total_unique += unique
        total_removed_dups += removed_dups

        print(f"✅ {vocab_file}")
        print(f"   → {unique} unique terms (removed {removed_dups} duplicates)")

    print(f"\n📊 Summary:")
    print(f"   Files processed: {total_files}")
    print(f"   Total unique terms: {total_unique}")
    print(f"   Total duplicates removed: {total_removed_dups}")
    print(f"\n✓ Ultra-cleaning complete! Ready for AWS Transcribe deployment.")

if __name__ == '__main__':
    main()
