<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xso="http://transpect.io/generate-xsl"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

  <!-- Invocation: saxon -s:file:///path/to/doc.xml -xsl:validate-and-render-svrl.xsl \
                   schema-uri=file:///path/to/schema.sch -o:out.html debug=true -->

  <xsl:param name="schema-uri" as="xs:string"/>
  <xsl:param name="debug" as="xs:boolean" select="false()"/>
  <xsl:param name="debug-dir-uri" as="xs:string?"/>
  
  <xsl:output name="debug" indent="true" omit-xml-declaration="false"/>
  
  <xsl:variable name="svrl" as="document-node(element())"
    select="transform(map{'stylesheet-location': 'validate-with-schematron.xsl',
                          'source-node': /,
                          'schema-uri': $schema-uri,
                          'stylesheet-params': map{xs:QName('schema-uri'): $schema-uri}
                         }) ? output">
  </xsl:variable>
  
  <xsl:template match="/">
    <xsl:sequence select="transform(map{'stylesheet-location': 'svrl2html.xsl',
                          'source-node': $svrl}) ? output"/>
    <xsl:result-document href="{$svrl/*/base-uri()}">
      <xsl:sequence select="$svrl"/>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>