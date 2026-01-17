# Custom Vocabularies for AWS Transcribe

This directory contains custom vocabulary files for improving transcription accuracy of medical terms and regional languages.

## Vocabulary Files

### 1. `medical-abbreviations.txt`
- **Language:** English (en-US)
- **Purpose:** Common medical abbreviations and acronyms
- **Terms:** 100+ abbreviations (BP, HR, IV, CBC, ECG, etc.)
- **Use Case:** All medical video calls

### 2. `pidgin-medical-terms.txt`
- **Language:** Nigerian Pidgin (pcm)
- **Purpose:** Medical terms in Nigerian Pidgin English
- **Terms:** 80+ common health-related phrases
- **Use Case:** West African patient consultations
- **Examples:** "wahala" (problem), "belle" (stomach), "body dey hot" (fever)

### 3. `camfranglais-medical-terms.txt`
- **Language:** Camfranglais (camfrang)
- **Purpose:** Medical terms in Cameroonian French-English creole
- **Terms:** 70+ medical phrases
- **Use Case:** Central African patient consultations
- **Examples:** "le dos" (back pain), "mal au ventre" (stomach ache)

### 4. `african-traditional-medicine.txt`
- **Language:** English (en-US)
- **Purpose:** Terms related to traditional African medicine
- **Terms:** 60+ traditional healing terms
- **Use Case:** Understanding traditional medicine references

## File Format

All vocabulary files follow AWS Transcribe's TSV (Tab-Separated Values) format:

```
Phrase	IPA	SoundsLike	DisplayAs
term1	[ipa]	sounds-like	Display As Text
term2		sounds-like-2	Display Text 2
```

### Columns:
- **Phrase** (required): The term to recognize
- **IPA**: International Phonetic Alphabet pronunciation (optional)
- **SoundsLike**: Pronunciation guide using common words (optional)
- **DisplayAs**: How to display the term in transcripts (optional)

## Usage

### 1. Upload to S3

```bash
# Upload all vocabularies
./upload-vocabularies.sh

# Or upload individual file
aws s3 cp pidgin-medical-terms.txt \
  s3://medzen-medical-data-558069890522/vocabularies/pidgin-medical-terms.txt
```

### 2. Register with AWS Transcribe

```bash
# Create vocabulary (done automatically by Lambda)
aws transcribe create-vocabulary \
  --vocabulary-name pidgin-medical-terms \
  --language-code en-US \
  --vocabulary-file-uri s3://medzen-medical-data-558069890522/vocabularies/pidgin-medical-terms.txt
```

### 3. Use in Transcription Jobs

The Lambda function `chime-recording-handler` automatically selects the appropriate vocabulary based on detected language and user preferences.

## Adding New Terms

### To add terms to existing vocabularies:

1. Edit the vocabulary file in TSV format
2. Upload to S3
3. Update the vocabulary in AWS Transcribe:

```bash
aws transcribe update-vocabulary \
  --vocabulary-name <vocab-name> \
  --language-code <lang-code> \
  --vocabulary-file-uri s3://path/to/file.txt
```

### To create a new vocabulary:

1. Create a new `.txt` file following the TSV format
2. Add entry to `custom_vocabularies` database table:

```sql
INSERT INTO custom_vocabularies (
  name,
  display_name,
  language_code,
  language_name,
  vocabulary_type,
  phrases
) VALUES (
  'my-custom-vocab',
  'My Custom Vocabulary',
  'language-code',
  'Language Name',
  'medical',
  '[{"phrase": "term", "display_as": "Display"}]'::jsonb
);
```

3. Upload and register using the script

## Vocabulary Limitations

### AWS Transcribe Limits:
- **Max phrases per vocabulary:** 50,000
- **Max phrase length:** 256 characters
- **Max vocabulary name length:** 200 characters
- **Processing time:** 15-30 minutes for large vocabularies

### Language Support:
- Custom vocabularies work best with officially supported AWS Transcribe languages
- For unsupported languages (Pidgin, Camfranglais), vocabularies help but may have reduced accuracy
- Some pronunciation guidance may not work perfectly for all accents

## Testing

Test vocabulary effectiveness:

```bash
# Record sample audio with vocabulary terms
# Run transcription with and without vocabulary
# Compare accuracy improvements

./test-vocabulary-accuracy.sh pidgin-medical-terms
```

## Maintenance

### Regular Updates:
1. **Monthly:** Review transcription logs for unrecognized medical terms
2. **Quarterly:** Add new medical abbreviations and procedures
3. **Annually:** Review and update pronunciation guides

### Quality Checks:
- Verify term frequency in actual consultations
- Remove rarely used terms (< 10 uses/year)
- Update based on user feedback

## Regional Customization

Different regions may need different vocabulary files:

- **West Africa:** Pidgin, Yoruba, Igbo, Hausa terms
- **East Africa:** Swahili medical terms
- **Southern Africa:** Zulu, Afrikaans terms
- **North Africa:** Arabic medical terms

Create region-specific vocabularies as needed.

## Contributing

To contribute new medical terms:

1. Follow TSV format exactly
2. Include pronunciation guidance for non-standard terms
3. Test with sample audio
4. Submit via pull request or contact system admin

## References

- [AWS Transcribe Custom Vocabularies](https://docs.aws.amazon.com/transcribe/latest/dg/custom-vocabulary.html)
- [IPA Chart](https://www.internationalphoneticassociation.org/content/ipa-chart)
- [Medical Abbreviations Reference](https://en.wikipedia.org/wiki/List_of_medical_abbreviations)
