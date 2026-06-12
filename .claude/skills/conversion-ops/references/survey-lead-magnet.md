# Survey-to-Lead-Magnet Engine (`scripts/survey_lead_magnet.py`)

Ingests survey CSV data, clusters respondents by pain point, and generates lead magnet briefs for each segment.

## Usage

```bash
# Basic usage — analyze survey CSV
python scripts/survey_lead_magnet.py --csv survey_responses.csv

# Specify which columns contain pain points / challenges
python scripts/survey_lead_magnet.py --csv survey.csv --pain-columns "biggest_challenge" "top_frustration"

# Limit number of segments
python scripts/survey_lead_magnet.py --csv survey.csv --top-segments 5

# JSON output
python scripts/survey_lead_magnet.py --csv survey.csv --json

# Save output
python scripts/survey_lead_magnet.py --csv survey.csv --output lead_magnets.json
```

## Output

- Pain point clusters with respondent counts
- Segments ranked by size and commercial potential
- For each top segment, a lead magnet brief:
  - Title, format (guide/checklist/template/calculator), hook
  - Content outline (5–7 sections)
  - Target CTA and distribution channel
  - Viral potential score + conversion potential score
- Prioritized implementation roadmap

## CSV Format

Questions as column headers, one respondent per row. Works with any survey tool export (Typeform, Google Forms, SurveyMonkey, etc.)
