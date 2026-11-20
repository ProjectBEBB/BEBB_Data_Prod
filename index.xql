xquery version "3.1";

module namespace idx="http://teipublisher.com/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dbk="http://docbook.org/ns/docbook";

declare variable $idx:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    ;
    declare variable $idx:bernoullis-ids := ('pers_DE-588-117589144', 'pers_DE-588-119166895', 'pers_DE-588-117589136', 'pers_DE-588-118509969', 
    'pers_DE-588-120475030', 'pers_DE-588-118509950', 'pers_DE-588-119112450', 'pers_DE-588-135542146', 'pers_DE-588-118656503');
    
    declare variable $idx:bernoullis := collection('/db/apps/bebb-data/data/Briefwechsel');

(:~
 : Helper function called from collection.xconf to create index fields and facets.
 : This module needs to be loaded before collection.xconf starts indexing documents
 : and therefore should reside in the root of the app.
 :)
declare function idx:get-metadata($root as element(), $field as xs:string) {
    let $header := $root/tei:teiHeader
    return
        switch ($field)
            case "title" return
                string-join((
                    $header//tei:msDesc/tei:head, $header//tei:titleStmt/tei:title[@type = 'main'],
                    $header//tei:titleStmt/tei:title,
                    $root/dbk:info/dbk:title,
                    $root//article-meta/title-group/article-title,
                    $root//article-meta/title-group/subtitle
                ), " - ")
            case "author" return (
                $header//tei:correspDesc/tei:correspAction/tei:persName,
                $header//tei:titleStmt/tei:author,
                $root/dbk:info/dbk:author,
                $root//article-meta/contrib-group/contrib/name
            )
            case "language" return
                head((
                    $header//tei:langUsage/tei:language/@ident,
                    $root/@xml:lang,
                    $header/@xml:lang
                ))
            case "date-sent" return 
                head(($header//tei:correspDesc/tei:correspAction[@type='sent']/tei:date/@when, $header//tei:correspDesc/tei:correspAction[@type='sent']/tei:date/@notBefore))
            case "place-sent" return
                $header//tei:correspAction[@type='sent']/tei:placeName/@key
            case "genre" return (
                idx:get-genre($header),
                $root/dbk:info/dbk:keywordset[@vocab="#genre"]/dbk:keyword
            )
            case "correspondent-id" return 
                $header//tei:correspDesc//tei:persName/@key 
            case "correspondent-name" return (
                $header//tei:correspDesc//tei:persName/text()
            )
            case "correspondent-main" return 
                $header//tei:ptr[@type eq 'Briefwechsel']/@target 
            case "briefwechsel" return
                ($header//tei:ptr[@type eq 'Briefwechsel']/@target, $header//tei:ptr[@type eq 'Korrespondenz']/@target)
            case "briefwechsel-key" return
                $header//tei:correspContext/tei:ref/@target
            case "correspondent-key" return
                $header//tei:correspAction//tei:persName[not(@role eq 'main')]/@key
            case "sender" return
                $header//tei:correspAction[@type eq 'sent']/tei:persName/@key
            case "addressee" return
                $header//tei:correspAction[@type eq 'received']/tei:persName/@key
            case "shelfmark" return
                $header//tei:idno[@type eq 'callNumber']
            case "status" return
                if ($header//tei:revisionDesc/@status = 'VarignonBand') then 'katalogisiert' else $header//tei:revisionDesc/@status
            case "korrespondenz" return
                $header//tei:ptr[@type eq 'Korrespondenz']/@target
            case "type" return head($header//tei:catDesc)
            case "header" return $header
            default return
                ()
};

declare function idx:is-search-placeholder($value as xs:string?) as xs:boolean {
    let $normalized := lower-case(normalize-space($value))
    return
        contains($normalized, "placeholder")
        or contains($normalized, "tobereplaced")
        or contains($normalized, "to_be_replaced")
};

declare function idx:search-status($value as xs:string?) as xs:string? {
    let $status := lower-case(normalize-space($value))
    return
        if ($status = ("katalogisiert", "inventarisiert", "varignonband")) then "inventarisiert"
        else if ($status = ("teikodiert", "transkribiert")) then "transkribiert"
        else if ($status = ("grundkommentiert", "kommentiert", "ediert")) then "ediert"
        else if ($status = ("druck", "gedruckt")) then "im-druck-ediert"
        else $status
};

declare function idx:search-facet($root as element(tei:TEI), $facet as xs:string) as xs:string* {
    let $header := $root/tei:teiHeader
    let $is-letter := starts-with(normalize-space(string($root/@xml:id)), "B_")
    let $participants := $header//tei:correspDesc//(tei:persName | tei:orgName)/@key ! normalize-space(.)
    let $exchange-explicit :=
        for $value in $header//tei:correspContext/tei:ptr[@type = "Briefwechsel"]/@corresp
        return tokenize(normalize-space($value), "\s+")[.]
    let $correspondence-explicit :=
        for $value in $header//tei:correspContext/tei:ptr[@type = "Korrespondenz"]/@corresp
        return tokenize(normalize-space($value), "\s+")[.]
    let $values :=
        switch ($facet)
            case "sender" return
                if ($is-letter) then
                    $header//tei:correspDesc/tei:correspAction[@type = "sent"]/(tei:persName | tei:orgName)/@key
                else
                    $header/tei:fileDesc/tei:titleStmt/tei:author/(tei:persName | tei:orgName)/@key
            case "addressee" return
                $header//tei:correspDesc/tei:correspAction[@type = "received"]/(tei:persName | tei:orgName)/@key
            case "exchange" return
                if (exists($exchange-explicit)) then $exchange-explicit
                else $participants[. = $idx:bernoullis-ids]
            case "correspondence" return
                if (exists($correspondence-explicit)) then $correspondence-explicit
                else $participants[not(. = $idx:bernoullis-ids)]
            case "place" return
                if (not($is-letter)) then
                    ()
                else
                    let $id := normalize-space(string((
                        $header//tei:correspDesc/tei:correspAction[@type = "sent"]/tei:placeName/@key
                    )[1]))
                    return if (not($id) or idx:is-search-placeholder($id)) then "unknown" else $id
            case "language" return $header//tei:langUsage/tei:language/@ident
            case "person-mentioned" return
                for $key in $root/tei:text//tei:rs[@type = ("person", "persons")]/@key
                return tokenize(normalize-space($key), "\s+")[.]
            case "place-mentioned" return
                for $key in $root/tei:text//tei:rs[@type = "place"]/@key
                return tokenize(normalize-space($key), "\s+")[.]
            case "work-mentioned" return
                for $key in $root/tei:text//tei:rs[@type = "biblio"]/@key
                return tokenize(normalize-space($key), "\s+")[.]
            case "organisation-mentioned" return
                for $key in $root/tei:text//tei:rs[@type = "organisation"]/@key
                return tokenize(normalize-space($key), "\s+")[.]
            case "repository" return $header//tei:sourceDesc//tei:msIdentifier/tei:repository
            case "collection" return
                for $value in $header/tei:fileDesc/tei:notesStmt/tei:note[@type = "dataGroup"]
                let $label := normalize-space(string($value))
                return if (matches(lower-case($label), "^tei[- ]xml$")) then "TEI XML" else $label
            case "facsimile" return
                if (exists(
                    $root/tei:facsimile/tei:graphic[
                        normalize-space(@url)
                        and not(contains(lower-case(@url), "placeholder"))
                        and not(contains(lower-case(@url), "fakeurl"))
                    ]
                )) then "yes" else "no"
            case "preservation" return
                let $value := lower-case(normalize-space(string((
                    $header/tei:fileDesc/tei:notesStmt/tei:note[@type = "erschliessbarkeit"]
                )[1])))
                return
                    if (not($value)) then "unknown"
                    else if (
                        contains($value, "nicht erhalten")
                        or contains($value, "verschollen")
                        or contains($value, "nicht nachgewiesen")
                    ) then "no"
                    else if (contains($value, "erhalten")) then "yes"
                    else "unknown"
            case "status" return idx:search-status(string(($header/tei:revisionDesc/@status)[1]))
            case "type" return normalize-space(string(($header//tei:catDesc)[1]))
            case "shelfmark" return
                $header//tei:sourceDesc//tei:msIdentifier/tei:idno[@type = "callNumber"]
            case "system" return
                for $idno in $header//tei:sourceDesc//tei:msIdentifier//tei:idno[
                    @type = ("ALMA_NZ", "ALMA_IZ", "ALEPH")
                ]
                return normalize-space(replace(string($idno/@type), "_", " ") || " " || string($idno))
            default return ()
    return
        distinct-values(
            $values ! normalize-space(string(.))
        )[. and not(idx:is-search-placeholder(.))]
};

declare function idx:get-idnos($header as element()) {
    let $idnos := $header//tei:altIdentifier/tei:idno
    let $formatted := for $idno in $idnos return replace($idno/@type, '_', ' ') || ' ' || $idno/string()
    return 
        $formatted
    };


declare function idx:has-facsimile($root as element()) {
    let $facsimile := $root//tei:facsimile/tei:graphic
    return if ($facsimile and not(matches($facsimile/@url, '[Ff]ake'))) then 'yes' else 'no'
    };

declare function idx:get-correspondent($header as element()) {
       $header//tei:correspDesc//tei:persName[not(@key = $idx:bernoullis-ids)]/@key 
    };
    
declare function idx:get-name-main($header as element()) {
   (:  : let $id := $header//tei:ptr[@type eq 'Briefwechsel']/@target
    let $main := $idx:bernoullis/id($id)//tei:persName
    return $main/text():)
    $header//tei:correspDesc//tei:persName[@key = $idx:bernoullis-ids]/text()
    };
    
declare function idx:get-normalizedText($text as element()) {
    let $contents := $text/descendant::tei:div[@type = ('letter', 'attachment')]
    let $textNodes := $contents//text()[not(ancestor::tei:orig)][not(ancestor::tei:pc[@type eq 'hyphenation'])][not(ancestor::tei:abbr)][not(ancestor::tei:note[@type = ('comment', 'editorial')])]
    return
        string-join($textNodes, '')
    };
    
declare function idx:get-diplomaticText($text as element()) {
    let $contents := $text/descendant::tei:div[@type = ('letter', 'attachment')]
    let $textNodes := $contents//text()[not(ancestor::tei:reg)][not(ancestor::tei:expan)][not(ancestor::tei:note[@type = ('comment', 'editorial')])]
    return
        string-join($textNodes, '')
    };
    
declare function idx:get-commentary($text as element(), $context as xs:string) {
    let $comments := ($text/descendant::tei:note[@type = ('editorial', 'comment')], $text/descendant::tei:div[@type eq 'editorialNote'])
    return 
        switch ($context)
            case 'document' return string-join($comments, '&#xA;')
            default return string-join(($comments, $text/ancestor::tei:TEI/tei:teiHeader/descendant::tei:abstract/tei:p), '&#xA;')
        
    };

declare function idx:get-name($person as element()) {
    let $names := $person/tei:persName
    let $var1 := string-join($names/*, ' ')
    let $var2 := for $name in $names return if ($name/tei:surname/text()) then $name/tei:surname || ', ' || $name/tei:forename else $name/tei:forename
    return string-join(($var1, $var2), ' ')};



declare function idx:get-genre($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#genre"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:is-preserved($header as element()) {
    let $status := $header/descendant::tei:note[@type eq 'erschliessbarkeit']
    return 
        switch($status) 
            case 'Nachgewiesen' return 'no'
            case 'Erhalten' return 'yes'
            case 'Privatbesitz' return 'yes'
            case 'Fragment' return 'yes'
            default return ()
};

declare function idx:normalization($node as item()*) as text() {
 let $replacements := map {"ö": "oe", "ä": "ae", "ü": "ue"}  
 return
    text {fold-left(map:keys($replacements), string($node), function($value, $key) {replace($value, $key, $replacements($key))})}
     
    };
