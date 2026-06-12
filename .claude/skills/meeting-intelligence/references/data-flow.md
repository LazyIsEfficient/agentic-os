# Data Flow

## Meeting Intelligence

```
Meeting Transcripts (text file / stdin / batch directory)
        │
        ▼
┌─────────────────────────────────────┐
│ scripts/meeting_action_extractor.py │
│   Extract:                          │
│   • Decisions (who + context)       │
│   • Action items (owner +           │
│     deadline + priority)            │
│   • Open questions                  │
│   • Key insights / quotes           │
│   • Follow-up meetings needed       │
│   • Implicit commitments            │
│   + Confidence scores               │
└─────────────────────────────────────┘
        │
        ▼
Structured JSON / Markdown + Optional HubSpot Task Push
```

### HubSpot push (`--push-hubspot`)

Each action item becomes a HubSpot task via the CRM v3 API
(`POST https://api.hubapi.com/crm/v3/objects/tasks`), authenticated with a
private-app token from `HUBSPOT_API_KEY`. Owner, deadline, and priority map onto
`hs_task_*` properties. Requires the optional `requests` dependency.
