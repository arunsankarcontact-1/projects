Repo structure

vpc-flowlogs-bedrock-analysis/
├── architecture/
│   ├── architecture.png
│   └── architecture.drawio
├── data/
│   ├── sample-flowlogs.csv
│   ├── aggregated-metrics.json
│   └── athena-query-results.csv
├── sql/
│   ├── top_source_ips.sql
│   ├── denied_ips.sql
│   ├── hourly_trends.sql
│   └── resource_access.sql
├── prompts/
│   └── bedrock-analysis-prompt.txt
├── output/
│   ├── bedrock-summary.md
│   └── charts/
│       ├── hourly-traffic.png
│       ├── top-source-ips.png
│       └── denied-ips.png
├── scripts/
│   ├── run-athena.sh
│   └── generate-charts.py
└── README.md
