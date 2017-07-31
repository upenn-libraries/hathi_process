# Hathi Process Documentation

This is a documentation repository intended to describe workflows facilitated by linked repos referenced herein.  Code is not maintained in this repository.

## Phase 1: ARK ID Generation

After selecting and validating that books are viable candidates to be sent through this process, this phase is the next thing that must be done before any catalogging work in service of final content package generation can happen. 

### Requirements
* Bib IDs of books to be sent to Hath

### Steps
1. Catalogging Team will open a ticket with LTS requesting ARK IDs be minted for books based on the bib IDs they have added to the Hathi scanned books spreadsheet on Box (shared with other staff on this project). 

2. Once the ticket is received, log into [EZID](https://ezid.cdlib.org/) and mint ARK IDs, one per book, adhering to the following values for the ERC schema:
    * Who: University of Pennsylvania Libraries
    * What: [TITLE IN CATALOG RECORD]
    * When: [PUBLICATION DATE IN CATALOG RECORD]
    * Where: Can be left blank for now.
    
    Note: values associated with an ARK ID can be updated at any time.  Credentials to log into and use this service are currently owned and managed by LTS.
    
3. Update the "EZID ARK" column in the spreadsheet on Box with the ARKS for each book.  This is a critical stage, as the process on Hathi's end requires a book's metadata and its files to be processed by two separate systems that rely exclusively on the ARK ID being the same to create correct content packages.

4. Update the support ticket and alert staff that this is complete.

## Phase 2: Generate manifests for image conversion

As noted above, the relationship between bib IDs and their associated ARK IDs is important to keep correct for Hathi.  For this reason, a simple script is used to generate manifest YAML files used in phase 3 to create appropriately-named directories and create JP2 versions of TIFF images in the right locations, used as sources for the final content packages.

### Requirements
* Spreadsheet with bib IDs and associated ARK IDs for each book
* Folders (one per book) with sequentially-named TIFF images of each cover/page image
* A manifest to run the bib_to_ark script (see [example](examples/bib_to_ark_manifest.example))

### Steps

1. From within the bib_to_ark root directory, run the script like so:
```
ruby bib_to_ark.rb $MANIFEST
```
Where ```$MANIFEST``` is the absolute path to the manifest file you wish to use.

2. There should now be YAML files named for the ARK IDs of each book referenced in the manifest in the directory from which you ran the script. Optionally copy them into the image_format_converter root directory for ease of command-line operations.

## Phase 3: Generating JP2s

The script in question [image_format_converter](image_format_converter) fulfills one purpose -- converting images in one location of one source format into another format at another location.  As such, the process described below is somewhat manual, however this could be automated or improved with supplementary bash scripts, etc.

### Requirements
* Folders (one per book) with sequentially-named TIFF images of each cover/page image
* A machine with access to ```sceti-completed```

### Steps
1. For each manifest file generated in phase 2, run the following command using the image conversion script:
```
ruby converter.rb $ARK_MANIFEST
```
Where ```$ARK_MANIFEST``` is the absolutely path to the object's ark manifest YAML file.

2. Observe through onscreen logging as images are processed by the script.  This script will warn the user if Hathi-compliany sequential image number appears to be off, specifically if pages seem to be missing based on the filenames present.  The user must give approval in order to proceed.

3. Once all images have been converted, proceed to content package generation.
 
## Phase 4: Generating content packages

 TODO
 
## Phase 5: Generating metadata record
 
 TODO
## Phase 6: Uploading to Hathi

 TODO