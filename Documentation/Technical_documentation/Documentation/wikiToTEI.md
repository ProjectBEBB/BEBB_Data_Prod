Last data export: August 2024. Step 1-6 performed last time October (from 3 to 10 roughly) 2024.


# Step 0: Obtain data from wiki
- Data dump obtained from UB (Martin Reisacher): https://drive.switch.ch/index.php/apps/files/?dir=/Bernoulli&fileid=7441540861.
- Load data in local mysql server: DB name 'BEBB202408', user 'root', pwd 'chief'
- Documentation: https://github.com/ProjectBEBB/wiki-to-xml/blob/master/bebb-import.md#parse-and-convert-mediawiki-contents

# Step 1: from Wiki to XML
- Github repo https://github.com/ProjectBEBB/wiki-to-xml, folder `BEBB`
- See detailed readme for code. Updates in code documented at https://github.com/ProjectBEBB/wiki-to-xml/pull/1 (new sql request)
- Get some errors, but converts all the 1531 letters
- Output: https://github.com/ProjectBEBB/wiki-to-xml/tree/master/BEBB/xml


# Step 2: from BEBB-XML to TEI-XML
Batch XSL transformation.
- Code: https://github.com/ProjectBEBB/Transformation-to-TEI.
- Documentation: https://github.com/ProjectBEBB/Transformation-to-TEI/blob/master/Transformation_proper/Transformation_docu.md.
- Output: https://github.com/ProjectBEBB/Transformation-to-TEI/tree/master/Transformation_proper/xml_transformed

Notes: Before running the transformation, take care of the following issues:
- `1695-03-15_TA_Bernoulli_Johann_I-Frick_Johannes.xml` and `1695-03-15_TP_Bernoulli_Johann_I-Frick_Johannes.xml` --> transform them one at a time (remember to remove entities) and change manually the output file name
- `1725-03-16_2_Bernoulli_Johann_I-Wolff_Christian.xml` and `1725-03-16_Bernoulli_Johann_I-Wolff_Christian.xml` --> transform them one at a time and change manually the output file name
- `xml/1708-11-05_Scheuchzer_Johannes-Bernoulli_Johann_I.xml` --> remove "--" in commentary `<!--<ref> $Kommentar$ Johannes Scheuchzers erste Berufung nach Padua, Link auf externen Kommentar setzen -->`
- `1740-11-15_Maupertuis_Pierre_Louis_Moreau_de-Bernoulli_Johann_II.xml` --> remove, it is empty, but remember that it should be added later only with the header.
The results after transformation:
* 1695-03-15_000055886_TA.xml
* 1695-03-15_000055886_TP.xml
* 1725-03-16_000057852_01.xml
* 1725-03-16_000057852_02.xml
are included back with the other transformed files.


# Step 3: manual edits by the team
Decided with Sulamith to postpone it to the end of the process.

# Step 4 and 5: teiHeader
Prepare teiHeader (step 4) and fill it with data from the library catalog (step 5). Batch XSL transformation and 3 Python scripts.
- Code: https://github.com/ProjectBEBB/TEI_Header.
- Documentation: https://github.com/ProjectBEBB/TEI_Header/blob/main/Scripts/Documentation_for_TEI_Header_Initial_Processing.md.
- Output: https://github.com/ProjectBEBB/TEI_Header/tree/main/Scripts/file_modifying_folder
- Check trouble file

# Step 6: adjustments
Improve headers (correspDesc, revisionDesc, IIIF links) and text (add paragraphs, replace rendition with rend). One Python script.
- Code: https://github.com/ProjectBEBB/TEI_Header/blob/main/Scripts/last_step_wikiLetters/step6.py
- Documentation: https://github.com/ProjectBEBB/TEI_Header/blob/main/Scripts/last_step_wikiLetters/readme.md
- Output: https://github.com/ProjectBEBB/TEI_Header/tree/main/Scripts/last_step_wikiLetters/transformed



# Special letters case

Take care of the letters manually at the end of the process.

- Wiki:	`1731-02-07_Maupertuis_Pierre_Louis_Moreau_de-Bernoulli_Johann_I`. Generated XML: `B_1731-02-07_991170514889405501`  and  `B_1731-02-07_991170525659005501`. Check manually.
- `Bernoulli_Letters_TEI/_Katalogisierte_Briefe/BW_JohIB/korr_Wolff_Christian-JohIB/B_1724-02-11_991170516536005501.xml`. Is there any problem here?
- `1740-11-15_Maupertuis_Pierre_Louis_Moreau_de-Bernoulli_Johann_II.xml` --> it is empty in the Wiki, but it should be added later only with the header.
- After step 2 (Wiki to XML, not yet TEI), we have these two files: `1695-03-15_000055886_TA.xml` and `1695-03-15_000055886_TP.xml`. The first one is transformed in `B_1695-03-15_991170514858605501.xml`, but the second gets lost in the subsequent processing and needs to be recreated manually.
- After step 2 (Wiki to XML, not yet TEI), we have these two files: `1725-03-16_000057852_01.xml` and `1725-03-16_000057852_02.xml`. The first one is transformed into `B_1725-03-16_991170430262805501.xml`, but the second gets lost in the subsequent processing and needs to be recreated manually.
- In trouble-file.txt from step 5 (BIBB to TEI Header), error messages:
	- `1743-01-09_000055654.xml	edit_idno_callnumber;`
	- `1725-01-20_000055892.xml	edit_idno_callnumber;`
	- `1725-10-13_000055626.xml	edit_idno_callnumber`
- Generated (status=bernoulliWiki in Bernoulli_Letters_TEI), but not among the letters transformed from the Wiki:
	* B_1706-09-11_991170524875305501.xml
	* B_1706_991170524875105501.xml
	* B_1708-09-27_991170514865805501.xml
	* B_1721-04-23_991170430267105501.xml
	* B_1723-12-15_991170462464305501.xml
	* B_1724-03-17_991170462463905501.xml
	* B_1724-05-21_991170462462405501.xml
	* B_1724-06-22_991170453971005501.xml
	* B_1728-01-14_991170453213905501.xml
