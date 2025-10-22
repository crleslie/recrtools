------------------------------------------------------------------------

# recrtools <img src="https://img.shields.io/badge/R-package-orange" alt="R package badge"/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

**recrtools** is an R package for researchers and land managers working with outdoor recreation data.\
It provides streamlined tools for **cleaning, formatting, and analyzing recreation monitoring data**, including automated processing of **trail counters**, **vehicle counts**, and **visitation datasets**.

The initial release focuses on working with **TRAFx ShuttleFiles** including reading, cleaning, and correcting timestamps for daylight saving time (DST).

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

-   **Dictionary-based recoding** for survey “Other” responses

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

### Dictionary-based recoding for survey “Other” responses

``` r
library(dplyr)

survey <- tibble(
  activity_select = c("Biking", "Other", "Other", "Running", "Other"),
  activity_other_text = c(NA, "mountain biking", "trail run with dog", NA, "skateboarding")
)

# Define a dictionary mapping categories to keywords
dict <- list(
  biking  = c("bike", "biking", "cycling"),
  running = c("run", "running")
)

# Apply recoding
survey <- survey %>%
  mutate(activity_recoded = recode_by_dict(activity_select, activity_other_text, dict))

survey
```

| activity_select | activity_other_text | activity_recoded |
|-----------------|---------------------|------------------|
| Biking          | NA                  | biking           |
| Other           | mountain biking     | biking           |
| Other           | trail run with dog  | running          |
| Running         | NA                  | running          |
| Other           | skateboarding       | other            |

------------------------------------------------------------------------

## 📚 Tutorials & Guides

-   [ShuttleFile workflow](vignettes/shuttlefile_workflow.Rmd)
-   [Survey recoding with dictionaries](vignettes/survey_recode.Rmd)
-   [Project folder structure](docs/folder_structure.md)
-   [Data dictionary](docs/data_dictionary.md)
-   [Contribution guidelines](docs/contributing.md)

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
