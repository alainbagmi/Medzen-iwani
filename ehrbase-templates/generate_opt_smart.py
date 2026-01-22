#!/usr/bin/env python3
"""
Smart OPT Generator - uses string-based template replacement
Reads a reference OPT file and replaces key fields for each MedZen template
"""

import os
import sys
import re
import uuid
from pathlib import Path
from typing import Dict, Tuple


def parse_adl(adl_path: str) -> Dict:
    """Parse ADL file to extract metadata"""
    metadata = {}

    try:
        with open(adl_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract purpose
        purpose_match = re.search(r'purpose = <"([^"]+)">', content)
        if purpose_match:
            metadata['purpose'] = purpose_match.group(1)
        else:
            metadata['purpose'] = 'To record clinical data.'

        # Extract author
        author_match = re.search(r'\["name"\] = <"([^"]+)">', content)
        if author_match:
            metadata['author_name'] = author_match.group(1)
        else:
            metadata['author_name'] = 'MedZen Health'

        metadata['original_language'] = 'en'

    except Exception as e:
        print(f"Warning: Could not parse ADL {adl_path}: {e}")

    return metadata


def load_reference_opt(opt_path: str) -> str:
    """Load reference OPT file"""
    try:
        with open(opt_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error loading reference OPT: {e}")
        return None


def find_reference_template(opt_dir: str) -> str:
    """Find a suitable reference OPT template"""
    opt_files = list(Path(opt_dir).glob('*.opt'))

    # Look for COMPOSITION-based templates
    for opt_file in opt_files:
        try:
            with open(opt_file, 'r') as f:
                content = f.read()
                if '<rm_type_name>COMPOSITION</rm_type_name>' in content:
                    print(f"Using reference template: {opt_file.name}")
                    return str(opt_file)
        except:
            continue

    # Fallback to smallest file (likely simpler structure)
    opt_files.sort(key=lambda p: os.path.getsize(p))
    if opt_files:
        print(f"Using fallback reference template: {opt_files[0].name}")
        return str(opt_files[0])

    return None


def generate_template_id(adl_name: str) -> str:
    """Generate template ID from ADL name"""
    # Convert: medzen-admission-discharge-summary.v1 -> medzen.admission.discharge.summary.v1
    name = adl_name.replace('.v1', '').replace('-', '.')
    return f"{name}.v1"


def adapt_opt_for_template(opt_content: str, adl_name: str, adl_metadata: Dict) -> str:
    """Adapt OPT content for specific template"""

    template_id = generate_template_id(adl_name)
    new_uid = str(uuid.uuid4())
    author = adl_metadata.get('author_name', 'MedZen Health')
    purpose = adl_metadata.get('purpose', 'To record clinical data.')

    # Replace template ID
    result = opt_content

    # Replace template IDs (both in template_id and concept)
    result = re.sub(
        r'<template_id>\s*<value>[^<]+</value>\s*</template_id>',
        f'<template_id>\n    <value>{template_id}</value>\n  </template_id>',
        result
    )

    result = re.sub(
        r'<concept>[^<]+</concept>',
        f'<concept>{template_id}</concept>',
        result
    )

    # Replace UID
    result = re.sub(
        r'<uid>\s*<value>[^<]+</value>\s*</uid>',
        f'<uid>\n    <value>{new_uid}</value>\n  </uid>',
        result
    )

    # Replace author
    result = re.sub(
        r'<original_author[^>]*>[^<]+</original_author>',
        f'<original_author id="Original Author">{author}</original_author>',
        result
    )

    # Replace purpose (first occurrence)
    result = re.sub(
        r'<purpose>[^<]*</purpose>',
        f'<purpose>{purpose}</purpose>',
        result,
        count=1
    )

    return result


def convert_adl_directory(source_dir: str, opt_template_dir: str, output_dir: str) -> Tuple[int, int]:
    """Convert ADL files using string-based template adaptation"""

    # Find reference OPT template
    reference_opt_path = find_reference_template(opt_template_dir)
    if not reference_opt_path:
        print("❌ No suitable reference OPT template found")
        return 0, 0

    reference_content = load_reference_opt(reference_opt_path)
    if not reference_content:
        print("❌ Could not load reference OPT file")
        return 0, 0

    Path(output_dir).mkdir(parents=True, exist_ok=True)

    adl_files = sorted(Path(source_dir).glob('*.adl'))

    print(f"\n{'='*60}")
    print(f"Smart OPT Generation (String-Based Templates)")
    print(f"{'='*60}")
    print(f"Reference: {Path(reference_opt_path).name}")
    print(f"Source: {source_dir}")
    print(f"Output: {output_dir}")
    print(f"Found {len(adl_files)} ADL files\n")

    successful = 0
    failed = 0

    for i, adl_file in enumerate(adl_files, 1):
        template_name = adl_file.stem
        progress = f"[{i:2d}/{len(adl_files)}]"

        try:
            # Parse ADL metadata
            adl_metadata = parse_adl(adl_file)

            # Adapt OPT content
            opt_content = adapt_opt_for_template(reference_content, template_name, adl_metadata)

            # Write OPT file
            opt_file = Path(output_dir) / f"{template_name}.opt"
            with open(opt_file, 'w', encoding='utf-8') as f:
                f.write(opt_content)

            # Basic validation (check for required elements)
            if '<template_id>' in opt_content and '<uid>' in opt_content:
                print(f"{progress} ✅ {template_name:40s}")
                successful += 1
            else:
                print(f"{progress} ⚠️  {template_name:40s} - Missing required elements")
                failed += 1

        except Exception as e:
            print(f"{progress} ❌ {template_name:40s} - {str(e)}")
            failed += 1

    print(f"\n{'='*60}")
    print(f"Conversion Complete: {successful} generated, {failed} failed")
    print(f"{'='*60}\n")

    return successful, failed


def main():
    """Main execution"""
    source_dir = '/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates/proper-templates'
    opt_template_dir = '/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates/opt-templates'
    output_dir = '/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates/opt-templates-medzen'

    successful, failed = convert_adl_directory(source_dir, opt_template_dir, output_dir)

    return 0 if failed == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
