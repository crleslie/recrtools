------------------------------------------------------------------------

# recrtools <img src="https://img.shields.io/badge/R-package-orange" alt="R package badge"/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**recrtools** is an R package for researchers and land managers working with outdoor recreation data.\
It provides streamlined tools for **cleaning, formatting, and analyzing recreation monitoring data**, including automated processing of **trail counters**, **vehicle counts**, and **visitation datasets**.

The initial release focuses on working with **TRAFx ShuttleFiles**—reading, cleaning, and correcting timestamps for daylight saving time (DST).

Future updates will extend support for other data sources and formats used in recreation monitoring and visitor use management.

------------------------------------------------------------------------

## 🚀 Current Features

-   Read and process **TRAFx ShuttleFiles** into tidy data frames:

    -   `counts` – hourly count data
    -   `header` – download metadata

-   Automatically correct timestamps for **Daylight Saving Time (DST)** shifts

-   Process **single files or entire folders**

-   Specify **time zones** or use the system default

-   Includes **example ShuttleFiles** for quick testing and reproducibility

------------------------------------------------------------------------

## 📦 Installation

``` r
# install.packages("remotes") # if not already installed
remotes::install_github("yourusername/recrtools")
library(recrtools)
```

------------------------------------------------------------------------

## 📝 Example Usage

### Read a single ShuttleFile

``` r
example_file <- system.file("extdata", "ShuttleFile_EXAMPLE.TXT", package = "recrtools")
data <- read_shuttlefile(example_file, return = "both")

counts <- data$counts
header <- data$header
```

### Batch process multiple files

``` r
data_folder <- "data/trafx_downloads/"
data <- read_shuttlefile(data_folder, return = "both")

counts <- data$counts
header <- data$header
```

### Adjust timestamps for daylight saving time

``` r
correct_dst("data/trafx_downloads/", direction = "begin", year = 2024)
```

------------------------------------------------------------------------

## 🧭 Roadmap

Planned additions include:

-   Functions for **aggregating and validating visitation data**
-   Standardized tools for **vehicle and trail count summaries**
-   **QA/QC utilities** for recreation monitoring workflows
-   Support for other common field data formats and sensors

------------------------------------------------------------------------

## 🛠 Folder Structure Recommendation

```         
TrailCounterProject/
├── data/               # raw ShuttleFiles and input data
├── results/            # processed outputs
├── scripts/            # scripts and functions
└── docs/               # documentation or reports
```

------------------------------------------------------------------------

## 🤝 Contributing

Contributions, suggestions, and bug reports are welcome! Open an issue or submit a pull request on [GitHub](https://github.com/crleslie/recrtools).

------------------------------------------------------------------------
