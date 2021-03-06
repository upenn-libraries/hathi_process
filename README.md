# README for `hathi_process`

Documentation and scripts to orchestrate HathiTrust content package generator and delivery.

## Setup

1. Install Tesseract for OCR.

   - [Tesseract install guide](https://guides.library.illinois.edu/c.php?g=347520&p=4121425)

2. Install Ruby dependencies:

   ```bash
   $ bundle install
   ```

3. When minting true arks for production, source environment variables for the Alma bibs API key and the EZID account credentials.

   ### EZID example:

   ```bash
   $ export EZID_DEFAULT_SHOULDER='$SHOULDER'
   $ export EZID_USER='$USERNAME'
   $ export EZID_PASSWORD='$PASSWORD'
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

The first argument (`examples/sample_ezid.xlsx` in the example) should be the path and filename for the local copy of the source spreadsheet from the metadata processing team. The second argument (`output.xlsx` in the example) should be the name of the path and filename of the new spreadsheet you are writing that will contain the ark IDs.

You should see output something like the following:

```bash
Writing spreadsheet...
I, [2020-03-17T15:30:46.672182 #84514]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4sj2td24
I, [2020-03-17T15:30:47.023855 #84514]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4ns23m0v
I, [2020-03-17T15:30:47.369654 #84514]  INFO -- : EZID MintIdentifier -- success: ark:/99999/fk4j11cs5n
Spreadsheet written to output.xlsx.
```

NOTE: The source spreadsheet **_must_** include valid MMS IDs with matching `Who`, `What`, and `When` values.

All HathiTrust books handled through this process **_must_** have the default value `University of Pennsylvania, Van Pelt-Dietrich Library` for `Who`.

**_IMPORTANT_**: Ark IDs created without production credentials sourced as environment variables (step 3 in `Setup` above) begin with `ark:/99999/fk4` and are intended for practice and testing. They expire automatically after 14 days.

Ark IDs for production that will persist over time for Penn Libraries begin with `ark:/81431/p3` and are created only with correct production credentials sourced as environment variables.

---

### Step 2

Spot-check the script's success by checking some of the EZID arks you'e created against their EZID URL - [example from EZID for ark:/81431/p37p8tf2t](https://ezid.cdlib.org/id/ark:/81431/p37p8tf2t).

Learn about the [ERC profile terms for EZID in the "Metadata profiles" section here](https://ezid.cdlib.org/doc/apidoc.html).

---

### Step 3

Send the newly populated spreadsheet you have generated back to metadata team to update catalog records with the newly-minted ark IDs.

NOTE: Steps 4 and 5 can be completed without the metadata yet being updated from this step. The metadata XML in step 6 must be generated **_after_** the metadata team has added the ark IDs to the catalog records.

**_IMPORTANT:_** The metadata XML with ark IDs can be sent to Hathi Trust before the content packages are uploaded. The content packages can also be sent to Hathi Trust before the metadata has been uploaded. The ark ID is the link between the descriptive metadata and the content package, linked by the ark ID in the catalog record and the name of the content package's directory.

---

### Step 4

The metadata spreadsheet will be updated with directories where the JP2 images to be scanned for OCR and included in the content packages are stored locally. Each content package will be in a directory named for its ark ID created in the spreadsheet in Step 1. For an example of what this looks like, an example exists as of 03/2020 on local storage at `sceti-completed-2/Temporary_sceti-completed/Hathi/Catalyst`.

Create a text manifest listing the directories containing the JP2 images to be OCR'd and converted to packages ([example](examples/list.example)) to generate content packages.

The manifest should be populated as follows, but with real values:

```
location|/absolute/path/to/Hathi_directories_to_process
destination|/absolute/path/to/Hathi_destination
/absolute/path/to/Hathi_directories/directory_1|bib_id_for_directory_1
destination|/absolute/path/to/Hathi_directories
/absolute/path/to/Hathi_directories/directory_2|bib_id_for_directory_2
destination|/absolute/path/to/Hathi_directories
/absolute/path/to/Hathi_directories/directory_3|bib_id_for_directory_3
```

Where `location` is the directory where all of the Hathi packages to be processed are, and `destination` is the destination for the completed Hathi zipped-up packages.

---

### Step 5

Use the [`hathi_ocr`](ruby/hathi_ocr.rb) Ruby script and the manifest to generate the Hathi content packages:

Example:

```bash
$ ruby ruby/hathi_ocr.rb examples/list.example
```

The finished packages will be at the path specified on the first line, after the string `destination|`.

---

### Step 6

Use the [`hathi_ocr`](ruby/hathi_ocr.rb) Ruby script and manifest to generate metadata XML and email terminal output.

Example:

```bash
$ ruby ruby/hathi_ocr.rb -m examples/list.example
```

You should see output something like the following:

```bash
Fetching MARC XML for /Users/kate/Documents/Hathi_stuff/Hathi_test/ark+=81431=p3pp4m, saving to /Users/kate/Downloads/Hathi_testing/metadata
Fetching MARC XML for /Users/kate/Documents/Hathi_stuff/Hathi_test/ark+=81431=p3bc7j, saving to /Users/kate/Downloads/Hathi_testing/metadata
Fetching MARC XML for /Users/kate/Documents/Hathi_stuff/Hathi_test/ark+=81431=p36p48, saving to /Users/kate/Downloads/Hathi_testing/metadata

Send to: cdl-zphr-l@ucop.edu
Subject: Zephir metadata file submitted

file name=PU-2_20200323_file1.xml
file size=11887
record count=3
notification email=katherly@upenn.edu
```

See [example metadata XML output](examples/PU-2_20200220_file1.xml).

Example email terminal output:

```bash
Send to: cdl-zphr-l@ucop.edu
Subject: Zephir metadata file submitted

file name=PU-2_20200220_file1.xml
file size=9754
record count=2
notification email=katherly@upenn.edu
```

This email **_does not send_** automatically. Save the email information outputted to the terminal and upload the metadata XML to the Zephir FTP server.

---

### Step 7

Upload the XML to the Zephir FTP server (credentials acquired from CDL through SCETI/Kislak Center contact for HathiTrust).

---

### Step 8

Once this is complete, retrieve the email terminal output. Copy and past the email address, subject line, and body of the email (change the notification email in the body to the appropriate Penn contact in LTS to be notified), and send the email. You will receive an automated email when the metadata has been processed.

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

In the event that **_all_** page images are not of appropriate quality or content for OCR, boilerplate OCR should be generated.

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

This **_will not_** generate the ZIP content packages, only the metadata XML file and email terminal output.

Example:

```bash
$ ruby ruby/hathi_ocr.rb examples/list -m
```

The XML will be saved to a folder called `metadata` at the path specified in the `destination` row of the manifest.

## Running with Docker

This project can be run with docker in one of two ways: by building the image and running the container manually or by running the convenience script `hathi_ocr.sh` to build and run the project for you.

### Using the script

To use the convenience script, run the following command:

```
./hathi_ocr.sh -f examples/list.example
```

The `-f` flag is used for supplying the location of the file you want to run with the script

If you need to mount volumes into your container you can add them to a file titled `.mounts` (one mount on each line) and the script will automatically add them. For example:

```
/mnt/first-mount
/mnt/second-mount
/mnt/third-mount
```

### Manually Building and Running

To build manually run the following command from the project's root directory:

```
docker build -t hathi_process .
```

Once the image is built you can then run a container to process the files:

```
docker run -it --rm \
    -v ./your_input_file:/usr/src/app/your_input_file" \
    -v ./destination:/usr/src/app/destination" \
    hathi_process ruby ruby/hathi_ocr.rb your_input_file
```
