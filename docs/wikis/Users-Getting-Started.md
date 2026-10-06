<!-- berrywiki
id: 01a1115e-33e1-7ee5-b13a-6879e2841886
parent: 01a1115e-33d5-7016-9f9d-1888ffbfe940
position: 10
kind: page
tags:
  - metamanifold
  - users
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Getting started

Summary of the README's [Prerequisites](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#prerequisites), [Installation](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#installation) and [Quick start](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#quick-start) sections at `257bcde`. Read those for the full detail.

## What you need

- **Julia 1.12** (`Project.toml` compat `julia = "1.12"`). `install.sh` installs it with juliaup if it is missing.
- **R ≥ 4.0**, for the DADA2 stage and for NMDS, PERMANOVA and differential abundance. Installing R and its system headers needs root: if R is missing, the installer stops and prints how to install it; if headers are missing, its summary prints the command.
- **bun**, to build the frontend. The installer uses a bun on `PATH` at the version pinned in `config/defaults/tool_versions.yml`, or downloads that release.

## Install and first run

```bash
git clone https://github.com/JoshuaJewell/MetaManifold-WebUI.git
cd MetaManifold-WebUI
bash install.sh          # Julia deps, external tools, R packages from renv.lock
# put paired-end .fastq.gz files under data/MyProject/run_A/
bash start.sh            # builds the frontend if needed, starts the server
```

Then open `http://localhost:8080`. The port is set by `JULIA_METAMANIFOLD_PORT` (default `8080`); see the table under [Quick start](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#quick-start).

`install.sh` ends with a summary marking every dependency `OK`, `SKIPPED` or `ACTION NEEDED`. Act on the last before your first run.

## Where things live

- **Inputs:** `data/{project}/[{group}/]{run}/*.fastq.gz`, Illumina naming (`..._L001_R1_001.fastq.gz`). The server treats any directory containing `.fastq.gz` files as a leaf run. See [Input data](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#input-data).
- **Outputs:** `projects/{project}/{run}/`, one subfolder per stage, ending in `merged/results.duckdb`, which the web UI queries. See [Output structure](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#output-structure).
- **Configuration:** a cascade (`config/defaults/`, then study, group and run `pipeline.yml` files), where each level overrides the one above it. It is editable in the web UI per study, per group or per run. See [Configuration](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#configuration).

## The path through the pipeline

cutadapt primer trimming → DADA2 (ASVs) or swarm (OTUs) → optional cd-hit-est → vsearch taxonomy → `merge_taxa` → DuckDB results, with optional phylogenetic placement (MAFFT, trimAl, IQ-TREE, RAxML EPA, gappa). The diagram in the README's [Overview](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#overview) marks which stages are optional.

Each stage is skipped when its outputs are up to date, so rerunning after a configuration change reruns only what that change affects ([Architecture](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#architecture)).

## After a run

Analysis is computed on request in the web UI, per run and across runs: alpha diversity, composition bars, taxon overlap (Euler or UpSet), NMDS and PERMANOVA with PERMDISP, and [[Users-Differential-Abundance]]. Counts can be normalised first (none, rarefy, or SRS).
