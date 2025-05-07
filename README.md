Below is a lean, reproducible build that gives you just enough R + system libraries to compile flowCore, drops all the build-time cruft, and exposes a single command you can script against or open in VS Code Dev Containers.

⸻

## 1  — Minimal Dockerfile


**Why R 4.4.3?**
Bioconductor 3.20 explicitly supports the whole 4.4 line; sticking to that avoids the compilation breakage you can hit on brand-new 4.5.0 today.  ￼ ￼

⸻

## 2  — Build the image

```
git clone https://github.com/<your-fork>/CytofBatchAdjust.git
cd CytofBatchAdjust
```

The final image is ~550 MB and contains nothing but R, flowCore, the script, and its shared libraries.

⸻

## 3  — Running the tool

• Batch / non-interactive

# Assume ./data has FCS files and ./output is empty
```
docker run --rm \
  -v "$PWD/data":/data \
  -v "$PWD/output":/output \
  batchadjust:0.1 \
  basedir='"/data"' \
  outdir='"/output"' \
  channelsFile='"/opt/batchadjust/Example/ChannelsToAdjust_example.txt"' \
  batchKeyword='"Barcode_"' \
  anchorKeyword='"anchor stim"' \
  method='"95p"'
```

Everything after batchadjust are R named arguments—quote them exactly as you would inside an R session.

**• Quick test run**

```
docker run --rm batchadjust:0.1 '--help'
```

⸻

## 4  — Interactive development in VS Code

Add a .devcontainer folder in the repo root:

devcontainer.json

{
  "name": "BatchAdjust Dev",
  "build": { "dockerfile": "../Dockerfile" },
  "extensions": [
    "REditorSupport.r",
    "ms-vscode-remote.remote-containers"
  ],
  "settings": {
    "terminal.integrated.defaultProfile.linux": "bash"
  },
  "postCreateCommand": "R -q -e 'install.packages(\"languageserver\");'"
}

Open the folder with “Remote-Containers: Re-open in Container”.
You’ll drop into /workspace, have IntelliSense for R, and can:

source("/opt/batchadjust/BatchAdjust.R")
BatchAdjust(basedir = "/workspace/ExampleInput",
            outdir   = "/workspace/Results")


⸻

5  — Vignette (“How-to”)

Step	Command	Notes
Build	docker build -t batchadjust:0.1 .	One-time; ~3 min on a fast link.
Dry-run / help	docker run --rm batchadjust:0.1 '--help'	Shows available arguments.
Adjust batches (CLI)	see Section 3	Mount any input/output paths you like.
Open in VS Code	Remote-Containers → Re-open	For exploratory tweaking, plotting, debugging.
Update R packages	docker build --no-cache …	Keeps the image immutable—re-build when you actually want fresh CRAN/Bioc bits.


⸻

6  — Extra tips
	•	Pin your Bioconductor snapshot. If you ever do need R ≥ 4.5, wait for Bioconductor 3.22 or install flowCore from source with --merge-multiarch.
	•	Keep data on the host. By mounting /data and /output you make the container completely stateless—and re-runnable—while still persisting results.
	•	Custom wrappers. If you frequently call the same parameter set, add a small shell script in your project to hide the long docker run … line.

⸻

You now have a single, minimal image that runs a 2019-era script on a 2025 system—either headless for pipelines or interactively in VS Code—with zero extra weight.






# BatchAdjust() - CyTOF Batch Adjust


Harmonize all samples in a cytometry experiment using anchor samples included in each batch to compute adjustment factors for each channel in each batch.



## Installation

BatchAdjust()   runs in the R environment.

Resources for installing and getting started with R are available at the Comprehensive R Archive Network:

https://cran.r-project.org/manuals.html




### Install required R packages

Install flowCore if you haven't already.


#### flowCore
At the R command line enter:
```
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("flowCore")
```



## Usage

BatchAdjust() is a command line application for R. It is designed to run in a linux environment or macOS.

In an R session, navigate to where you downloaded BatchAdjust.R, and load the application by typing:

```

source("BatchAdjust.R")

```



# Arguments

```
BatchAdjust(
   basedir=".",
   outdir=".",
   channelsFile = "ChannelsToAdjust.txt",
   batchKeyword="Barcode_",
   anchorKeyword = "anchor stim",
   method="95p",
   transformation=FALSE,
   addExt=NULL,
   plotDiagnostics=TRUE)
```



###### basedir: 
directory to look for input (source) FCS files. All files to be adjusted must be in this directory.

###### outdir:  
directory to write resulting batch adjusted files. Must not be the same as basedir to avoid overwriting original data files, unless addExt is set (see below). 


###### channelsFile: 
plain text file listing channels to adjust, one per line. 
Only channels listed here will be adjusted, and only channels that should be adjusted should be listed here. E.g. open channels and barcoding channels should be omitted from this file. 
Channel names must match those in the FCS files exactly.

For an example, see ChannelsToAdjust\_example.txt.

###### batchKeyword:
"Barcode\_" (refer to File naming requirements)

###### anchorKeyword:
"anchor stim" (refer to File naming requirements)


###### method:
95p | SD | quantile

quantile: quantile normalization

SD: scaling to reference batch standard deviation

50p: scaling to reference batch 50th percentile (median)

95p: scaling to reference batch 95th percentile

Batches may be scaled to an user-defined percentile by specifying any number (1-100) followed by the letter 'p'. For example method="80p" would scale channels to the 80th percentile of the reference batch.


###### transformation:
 TRUE | FALSE

TRUE: asinh transformation is applied before batch adjustment. sinh is applied to the adjusted data before writing results.

FALSE: No transformation is applied.


###### addExt:
A character string to append to output filenames (before .fcs extension) to distinguish from input filenames.

With the default=NULL, output filenames are identical to input filenames.
If addExt is not NULL, basedir and outdir may be the same directory.


###### plotDiagnostics:
 TRUE | FALSE

Generate distribution plots for each adjusted channel for all batch anchor samples before and after adjustment.

Also generate a figure summarizing permutation test results for decreased variability in signal levels among batches for all channels.

Note: this may take longer than the adjustment process itself. It is safe to interrupt this process, and doing so will not affect the batch adjusted .fcs files.




# File naming requirements:

Filenames for FCS files to be batch adjusted must contain a reference to which batch they belong.

One sample from each batch must also contain the anchor keyword defined by the parameter "anchorKeyword" to indicate the control sample expected to be consistent across batches.

Adjustments for all batches are relative to batch 1, and samples in batch 1 are not changed. Therefore one batch must be must be labeled as batch 1. To change your reference batch, simply rename your files.




##### Non-Anchor file naming:   
xxx[batchKeyword][##]\_xxx.fcs

'xxx' is optional and may be any characters.

Note that underscore '\_' is required after batch number (to distinguish e.g. Batch10\_ from Batch1\_).



##### Anchor file naming:   
xxx[batchKeyword][##]\_[anchorKeyword]xxx.fcs

'xxx' is optional and may be any characters.

Note that no other characters are allowed between [batchKeyword][##]\_[anchorKeyword].

Note that underscore '\_' is required after batch number (to distinguish e.g. Batch10\_ from Batch1\_).

Separators such as '\_' are allowed, but must be specified in the anchor keywords.





###### File name examples 1:

011118\_Barcode\_7\_anchor stim.fcs (anchor sample)

011118\_Barcode\_7\_310A\_T0.fcs

011118\_Barcode\_7\_310A\_T6.fcs

011118\_Barcode\_7\_310A\_T6\_R.fcs



For the above file name examples, batchKeyword and anchorKeyword parameters should be set as follows:

batchKeyword = "Barcode\_"

anchorKeyword = "anchor stim"





###### File name examples 2:

Set10\_CTstim.fcs (anchor sample)

Set10\_CCP13T0.fcs

Set10\_CCP13T6LPS.fcs

Set10\_CCP13T6PBS.fcs

Set10\_CCP13T6R848.fcs



For the above file name examples, batchKeyword and anchorKeyword parameters should be set as follows:

batchKeyword = "Set"

anchorKeyword = "CTstim"










