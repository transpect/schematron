<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xso="http://transpect.io/generate-xsl"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

  <!-- Invocation: saxon -s:file:///path/to/doc.xml -xsl:validate-with-schematron.xsl \
                   schema-uri=file:///path/to/schema.sch -o:out.svrl debug=true -->

  <xsl:param name="schema-uri" as="xs:string"/>
  <xsl:param name="debug" as="xs:boolean" select="false()"/>
  <xsl:param name="debug-dir-uri" as="xs:string?"/>
  <xsl:param name="full-path-notation" as="xs:string" select="'1'">
    <!-- full-path-notation = 1|2|3  select the notation for the full paths: 1=computer, 2=human, 3=obsolescent -->
  </xsl:param>
  
  <xsl:namespace-alias result-prefix="xsl" stylesheet-prefix="xso"/>
  
  <xsl:output name="debug" indent="true" omit-xml-declaration="false"/>

  <xsl:variable name="base-uri" as="xs:string" select="/*/base-uri()"/>
  
  <xsl:variable name="dsdl-includes" as="document-node(element(sch:schema))"
    select="map:get(transform(map{'stylesheet-location': '../dist/iso_dsdl_include.xsl',
                                  'base-output-uri': $base-uri,
                                  'source-location': $schema-uri}), $base-uri)">
  </xsl:variable>
  
  <xsl:variable name="expanded-abstract-patterns" as="document-node(element(sch:schema))"
    select="map:get(transform(map{'stylesheet-location': '../dist/iso_abstract_expand.xsl',
                                  'base-output-uri': $base-uri,
                                  'source-node': $dsdl-includes}), $base-uri)">
  </xsl:variable>
  
  <xsl:variable name="generated-xsl" as="document-node(element(xsl:stylesheet))"
    select="map:get(transform(map{'stylesheet-location': '../dist/iso_svrl_for_xslt2.xsl',
                          'source-node': $expanded-abstract-patterns,
                          'base-output-uri': $base-uri,
                          'stylesheet-params': map{
                                                 xs:QName('allow-foreign'): 'true',
                                                 xs:QName('full-path-notation'): $full-path-notation
                                               }
                         }), $base-uri)">
  </xsl:variable>

  <xsl:template match="/">
    <xsl:if test="$debug">
      <xsl:call-template name="debug">
        <xsl:with-param name="debug-dir-uri" 
          select="($debug-dir-uri, replace(base-uri(), '^(.+/).+$', '$1') || 'debug-sch/')[1]"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:sequence select="map:get(transform(map{'stylesheet-node': $generated-xsl,
                                                'base-output-uri': $base-uri,
                                                'source-node': .
                                               }), $base-uri)"/>
  </xsl:template>
  
  <xsl:template name="debug">
    <xsl:param name="debug-dir-uri" as="xs:string"/>
    <xsl:result-document href="{$debug-dir-uri}1.dsdl-includes.xml" format="debug">
      <xsl:sequence select="$dsdl-includes"/>
    </xsl:result-document>
    <xsl:result-document href="{$debug-dir-uri}2.abstract-expand.xml" format="debug">
      <xsl:sequence select="$expanded-abstract-patterns"/>
    </xsl:result-document>
    <xsl:result-document href="{$debug-dir-uri}3.generated.xsl" format="debug">
      <xsl:sequence select="$generated-xsl"/>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>