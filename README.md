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
    $ export ezid_p='export EZID_DEFAULT_SHOULDER='$SHOULDER';
    $ export EZID_USER='$USERNAME';
    $ export EZID_PASSWORD='$PASSWORD';'
    ```
    
    Where `$SHOULDER`, `$USERNAME`, and `$PASSWORD` are the EZID account values for production.
    
    ### Alma example: 
    
    ```bash
    $ export ALMA_KEY=$KEY_VALUE
    ```
    
    Where `$KEY_VALUE` is the Alma bibs API key you want to use.
    

## Content package generation and delivery process

1. Mint ark IDs and update their ERC profiles with information from a spreadsheet from metadata processing team [ruby/ezid_spreadsheet.rb](ruby/ezid_spreadsheet.rb) with [examples/sample_ezid_sheet.xlsx](examples/sample_ezid.xlsx).  Spot-check the script's success at an EZID URL from the resulting spreadsheet - [example from EZID](https://ezid.cdlib.org/id/ark:/99999/fk4572r527).

2. Send sheet back to metadata team to update catalog records.

3. ??? How get bibs? (these need to be on the original spreadsheet).

4. TODO: creating packages 

5. Generate metadata XML and email terminal output.  [Example metadata XML](examples/PU-2_20200220_file1.xml).
      
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
      
6. Upload the XML to the FTP server.
 
7. Once this is complete, retrieve the email terminal output.  Copy and past the email address, subject line, and body of the email (change the notification email in the body to the appropriate Penn contact in LTS to be notified), and send the email.  You will receive an automated email when the metadata has been processed. 
 
8. 

## Examples of `hathi_ocr`

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
$ ruby ruby/hathi_ocr.rb examples/list right-to-left -b
```

### Metadata-only (-m)

NOTE: to successfully generate metadata, make sure a read-only Alm bib data API key has been sourced to your environment by running the following in your terminal:

```bash
$ export ALMA_KEY=$KEY_VALUE
```

Where `$KEY_VALUE` is the Alma API key you want to use.

To generate the metadata XML file and email terminal output for steps 5 through 7, add the`-m` flag.  

This ***will not*** generate the ZIP content packages, only the metadata XML file and email terminal output.

Example:

```bash
$ ruby ruby/hathi_ocr.rb examples/list -m
```

The XML will be saved to a folder called `metadata` at the path specified in the `destination` row of the manifest.