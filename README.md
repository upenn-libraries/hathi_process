# README for `hathi_process`

Documentation and scripts to orchestrate HathiTrust content package generator and delivery.

## Setup

1. Install Tesseract for OCR.
    * [Tesseract install guide](https://guides.library.illinois.edu/c.php?g=347520&p=4121425)

2. Install Ruby dependencies:

    ```bash
    $ bundle install
    ```

3. Source environment variables for the Alma bibs API key and the EZID account credentials.  

    ### EZID example:

    ```bash
    $ export EZID_DEFAULT_SHOULDER='$SHOULDER';
    $ export EZID_USER='$USERNAME';
    $ export EZID_PASSWORD='$PASSWORD';
    ```

    Where `$SHOULDER`, `$USERNAME`, and `$PASSWORD` are the EZID account values for production.

    ### Alma example:

    ```bash
    $ export ALMA_KEY=$KEY_VALUE
    ```

    Where `$KEY_VALUE` is the Alma bibs API key you want to use.

## Content package generation and delivery process

### Step 1

Use the [`ezid_spreadsheet`](ruby/ezid_spreadsheet.rb) Ruby script to mint ark IDs and update their ERC profiles with information from a spreadsheet from the metadata processing team [Example](examples/sample_ezid.xlsx).

Example:
```bash
$ ruby ruby/ezid_spreadsheet.rb examples/sample_ezid.xlsx output.xlsx
```

The first argument (`examples/sample_ezid.xlsx` in the example) should be the path and filename for the local copy of the source spreadsheet from the metadata processing team.  The second argument (`output.xlsx` in the example) should be the name of the path and filename of the new spreadsheet you are writing that will contain the ark IDs.

You should see output something like the following:

```bash
Writing spreadsheet...
I, [2020-03-17T15:30:46.672182 #84514]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4sj2td24
I, [2020-03-17T15:30:47.023855 #84514]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4ns23m0v
I, [2020-03-17T15:30:47.369654 #84514]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4j11cs5n
Spreadsheet written to output.xlsx.
```

NOTE: The source spreadsheet ***must*** include valid MMS IDs with matching `Who`, `What`, and `When` values.  

All HathiTrust books handled through this process ***must*** have the default value `University of Pennsylvania, Van Pelt-Dietrich Library` for `Who`.

---

### Step 2

Spot-check the script's success by checking some of the EZID arks you'e created against their EZID URL - [example from EZID for ark:/99999/fk4572r527](https://ezid.cdlib.org/id/ark:/99999/fk4572r527).

Learn about the [ERC profile terms for EZID in the "Metadata profiles" section here](https://ezid.cdlib.org/doc/apidoc.html).

---

### Step 3

Send the newly populated spreadsheet you have generated back to metadata team to update catalog records.

---

### Step 4

Create a text manifest listing the directories containing the JP2 images to be OCR'd and converted to packages ([example](examples/list.example)) to generate content packages.

The manifest should be populated as follows, but with real values:

```
destination|/absolute/path/to/Hathi_directories
/absolute/path/to/Hathi_directories/directory_1|bib_id_for_directory_1
destination|/absolute/path/to/Hathi_directories
/absolute/path/to/Hathi_directories/directory_2|bib_id_for_directory_2
destination|/absolute/path/to/Hathi_directories
/absolute/path/to/Hathi_directories/directory_3|bib_id_for_directory_3
```

Use the [`hathi_ocr`](ruby/hathi_ocr.rb) Ruby script and the manifest to generate the Hathi content packages:

Example:

```bash
$ ruby ruby/hathi_ocr.rb examples/list.example
```

The finished packages will be at the path specified on the first line, after the string `destination|`.

---

### Step 5

Generate metadata XML and email terminal output.  [Example metadata XML](examples/PU-2_20200220_file1.xml).

Example email terminal output:

```bash      
Send to: cdl-zphr-l@ucop.edu
Subject: Zephir metadata file submitted

file name=PU-2_20200220_file1.xml
file size=9754
record count=2
notification email=katherly@upenn.edu
```

This email ***does not send*** automatically.      Save the email information outputted to the terminal and upload the metadata XML to the Zephir FTP server.

---

### Step 6

Upload the XML to the Zephir FTP server (credentials acquired from CDL through SCETI/Kislak Center contact for HathiTrust).

---

### Step 7

Once this is complete, retrieve the email terminal output.  Copy and past the email address, subject line, and body of the email (change the notification email in the body to the appropriate Penn contact in LTS to be notified), and send the email.  You will receive an automated email when the metadata has been processed.

---

## Usage of `hathi_ocr`

To see options available with `hathi_ocr` script:

```bash
$ ruby ruby/hathi_ocr.rb -h
$ ruby ruby/hathi_ocr.rb --help
```

Output:

```bash
Usage: hathi_ocr.rb [options]
    -b, --[no-]ocr                   Do not generate OCR (use boilerplate text)
    -m, --metadata-only              Fetch MARC XML only
```

### Reading directions

To specify left-to-right reading direction, do not specify a second argument to the `hathi_ocr` script.  

Example:

```bash
$ ruby ruby/hathi_ocr.rb examples/list
```

To specify a different reading order, add a second argument.  

Example for `right-to-left`:

```bash
$ ruby ruby/hathi_ocr.rb examples/list right-to-left
```

### Boilerplate OCR (-b)

In the event that ***all*** page images are not of appropriate quality or content for OCR, boilerplate OCR should be generated.  

Example:

```bash
$ # left-to-right
$ ruby ruby/hathi_ocr.rb examples/list -b
$
$ # right-to-left
$ ruby ruby/hathi_ocr.rb examples/list right-to-left -b
```

### Metadata-only (-m)

NOTE: to successfully generate metadata, make sure a read-only Alm bib data API key has been sourced to your environment by running the following in your terminal:

```bash
$ export ALMA_KEY=$KEY_VALUE
```

Where `$KEY_VALUE` is the Alma API key you want to use.

To generate the metadata XML file and email terminal output for steps 4 through 6, add the`-m` flag.  

This ***will not*** generate the ZIP content packages, only the metadata XML file and email terminal output.

Example:

```bash
$ ruby ruby/hathi_ocr.rb examples/list -m
```

The XML will be saved to a folder called `metadata` at the path specified in the `destination` row of the manifest.
