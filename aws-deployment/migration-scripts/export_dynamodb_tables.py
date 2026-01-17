#!/usr/bin/env python3
"""
MedZen DynamoDB to Supabase Migration: Data Export
Exports all records from three legacy DynamoDB tables to JSON files
suitable for transformation and insertion into Supabase PostgreSQL tables.

Usage:
    python3 export_dynamodb_tables.py \
        --region us-east-1 \
        --output-dir ./migration-data \
        --tables medzen-video-sessions medzen-soap-notes medzen-meeting-audit
"""

import json
import boto3
import argparse
import os
from datetime import datetime
from decimal import Decimal
from typing import Dict, List, Any


class DynamoDBJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder for DynamoDB Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj) if obj % 1 else int(obj)
        return super().default(obj)


def export_dynamodb_table(
    dynamodb_client,
    table_name: str,
    output_file: str,
    max_items: int = None
) -> Dict[str, Any]:
    """
    Export all items from a DynamoDB table to JSON file

    Args:
        dynamodb_client: boto3 DynamoDB resource
        table_name: Name of DynamoDB table to export
        output_file: Path to output JSON file
        max_items: Maximum items to export (None = all)

    Returns:
        Export statistics dict
    """

    print(f"\n[Export] Starting export from table: {table_name}")

    table = dynamodb_client.Table(table_name)
    items = []
    scan_kwargs = {}
    done = False
    start_key = None

    try:
        while not done:
            if start_key:
                scan_kwargs['ExclusiveStartKey'] = start_key

            response = table.scan(**scan_kwargs)
            items.extend(response.get('Items', []))

            # Check if we've reached max_items limit
            if max_items and len(items) >= max_items:
                items = items[:max_items]
                break

            start_key = response.get('LastEvaluatedKey')
            done = not start_key

            print(f"  Scanned {len(items)} items so far...")

        print(f"[Export] Total items to export: {len(items)}")

        # Write to JSON file
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, 'w') as f:
            json.dump(items, f, cls=DynamoDBJSONEncoder, indent=2)

        print(f"[Export] Successfully exported to {output_file}")

        return {
            'table_name': table_name,
            'item_count': len(items),
            'output_file': output_file,
            'status': 'success'
        }

    except Exception as e:
        print(f"[Export] ERROR exporting table {table_name}: {str(e)}")
        return {
            'table_name': table_name,
            'item_count': 0,
            'output_file': output_file,
            'status': 'failed',
            'error': str(e)
        }


def validate_export(export_stats: List[Dict[str, Any]]) -> bool:
    """
    Validate export results

    Args:
        export_stats: List of export statistics from each table

    Returns:
        True if all exports successful, False otherwise
    """

    print("\n[Validation] Export Results:")
    print("-" * 80)

    all_successful = True
    total_items = 0

    for stat in export_stats:
        status_indicator = "✓" if stat['status'] == 'success' else "✗"
        print(f"{status_indicator} {stat['table_name']}: {stat['item_count']} items")

        if stat['status'] == 'failed':
            print(f"  Error: {stat.get('error', 'Unknown error')}")
            all_successful = False
        else:
            total_items += stat['item_count']

    print("-" * 80)
    print(f"Total items exported: {total_items}")
    print(f"Overall status: {'SUCCESS' if all_successful else 'FAILED'}")

    return all_successful


def main():
    parser = argparse.ArgumentParser(
        description='Export DynamoDB tables for migration to Supabase'
    )
    parser.add_argument(
        '--region',
        default='us-east-1',
        help='AWS region (default: us-east-1)'
    )
    parser.add_argument(
        '--output-dir',
        default='./migration-data',
        help='Output directory for JSON files (default: ./migration-data)'
    )
    parser.add_argument(
        '--tables',
        nargs='+',
        default=['medzen-video-sessions', 'medzen-soap-notes', 'medzen-meeting-audit'],
        help='DynamoDB tables to export'
    )
    parser.add_argument(
        '--max-items',
        type=int,
        default=None,
        help='Maximum items to export per table (default: all)'
    )

    args = parser.parse_args()

    print("=" * 80)
    print("MedZen DynamoDB to Supabase Migration: Data Export")
    print("=" * 80)
    print(f"AWS Region: {args.region}")
    print(f"Output Directory: {args.output_dir}")
    print(f"Tables to export: {', '.join(args.tables)}")
    if args.max_items:
        print(f"Max items per table: {args.max_items}")

    # Initialize DynamoDB client
    try:
        dynamodb = boto3.resource('dynamodb', region_name=args.region)
        print("\n[Setup] Connected to DynamoDB")
    except Exception as e:
        print(f"[Setup] ERROR: Failed to connect to DynamoDB: {str(e)}")
        print("       Ensure AWS credentials are configured (aws configure)")
        return 1

    # Export each table
    export_results = []
    for table_name in args.tables:
        output_file = os.path.join(
            args.output_dir,
            f"{table_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )

        result = export_dynamodb_table(
            dynamodb,
            table_name,
            output_file,
            args.max_items
        )
        export_results.append(result)

    # Validate results
    all_successful = validate_export(export_results)

    if all_successful:
        print("\n[Success] All exports completed successfully")
        print("\nNext steps:")
        print("1. Review exported JSON files for data accuracy")
        print("2. Run transform_and_insert.sql to load data into Supabase")
        print("3. Run validate_migration.sql to verify data integrity")
        print("4. Check CLAUDE.md migration completion section")
        return 0
    else:
        print("\n[Failed] Some exports failed. Review errors above.")
        return 1


if __name__ == '__main__':
    exit(main())
