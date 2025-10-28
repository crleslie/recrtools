------------------------------------------------------------------------

# recrtools <img src="https://img.shields.io/badge/R-package-orange" alt="R package badge"/>   [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

**recrtools** is an R package for researchers and land managers working with outdoor recreation data.\
It provides streamlined tools for **cleaning, formatting, and analyzing recreation monitoring data**, including automated processing of **trail counters**, **vehicle counts**, and **visitation datasets**.

The initial release focuses on working with TRAFx ShuttleFiles including reading, cleaning, and correcting timestamps for daylight saving time (DST) as well as basic survey data cleaning and validation tasks.

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
remotes::install_github("crleslie/recrtools")
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

## 🧭 Roadmap

Planned additions include:

-   Functions for **aggregating and validating visitation data**
-   Standardized tools for **vehicle and trail count summaries**
-   **QA/QC utilities** for survey and recreation monitoring workflows
-   Support for other common field data formats and sensors

------------------------------------------------------------------------

## 🛠 Using an IDE and Folder Structure

Using an Integrated Development Environment (IDE) rather than simply running scripts in base R will greatly improve your workflow and user experience. **RStudio** is a popular IDE — it’s the one I personally use — and it allows you to create and manage RStudio Projects.

A project is a collection of files for an analysis or data task that are organized into a single folder, with a file named `YourProjectName.Rproj`. When you open a project, RStudio automatically sets the working directory to the project’s root folder and opens a dedicated environment that keeps your scripts, data, and objects organized during your session.

Setting the working directory to the root folder means you can define file paths **relative to the project root** (e.g., `"data/filename.csv"`) rather than using a full absolute path (e.g., `"C:/Users/.../filename.csv"`). This makes your project more portable — you can move it, open it from different computers, or share it with colleagues without breaking your file paths.

To keep your work organized and reproducible, adopt a consistent folder structure. The example below is based on guidance from [Good enough practices for scientific computing (Wilson et al., 2017)](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1005510), which provides practical advice for organizing research code and data:

```         
TrailCounterProject/
├── data/                     # raw ShuttleFiles and input data
├── results/                  # processed outputs and intermediate files
├── scripts/                  # scripts and functions
├── docs/                     # documentation or reports
└── TrailCounterProject.Rproj # RStudio project file
```

This structure separates inputs, processing, and outputs, making it easy to see where each type of file belongs. Keeping your raw data in one place (data folder) — and treating it as read-only — helps preserve data integrity.

A few practical tips: 

- Use **relative paths** (e.g., `"data/filename.csv"`) to keep your project portable.
- Give scripts and files **clear, consistent names** (e.g., `clean_counts.R`, `summarize_daily_visits.R`).
- Store both **scripts** and **functions** in the `scripts/` folder — functions can either live in separate helper files or at the top of your main scripts. Annotate your scripts. Your future self will thank you.
- Store processed data (e.g., `"hourly_counts.csv"`, `"hourly_counts.RDS"` files) and graphical ouputs (plots) in `results/` - Keep notes, figures, or write-ups in the `docs/` folder to keep your analysis and reporting connected.

With this setup, you can simply open the `.Rproj` file in RStudio to get started — your working directory, environment, and paths will all be configured automatically.

------------------------------------------------------------------------

## 🤝 Contributing

Contributions, suggestions, and bug reports are welcome! Open an issue or submit a pull request on [GitHub](https://github.com/crleslie/recrtools).

------------------------------------------------------------------------

## 📄 References

Wilson, G., Bryan, J., Cranston, K., Kitzes, J., Nederbragt, L., & Teal, T. K. (2017). Good enough practices in scientific computing. *PLOS Computational Biology, 13*(6), e1005510. <https://doi.org/10.1371/journal.pcbi.1005510>
