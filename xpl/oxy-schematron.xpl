<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  type="tr:oxy-validate-with-schematron"
  name="validate-with-schematron"
  version="3.1">
  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>A Schematron validation step that uses oXygen’s abstract expansion XSL by default.</p>
    <p>The reason for selecting oXygen’s implementation is that it expands placeholders in (sch:report | sch:assert)/@role.</p>
    <p>It isn’t fully featured yet. For example, assert-valid doesn’t have an effect.</p>
  </p:documentation>
  <p:option name="family" select="'unspecified'">
    <p:documentation>The Schematron checking rule “family”, a set of rules with same categories. They will be
    displayed by tr:patch-svrl.</p:documentation>
  </p:option>
  <p:option name="step-name" select="''">
    <p:documentation>The XProc step whose output has been checked. This will be displayed by tr:patch-svrl.</p:documentation>
  </p:option>
  <p:option name="assert-valid" select="'false'"/>
  <p:option name="phase" select="'#ALL'"/>
  <p:option name="parameters" as="map(xs:QName, item()*)?" required="false" select="()"/>
  <p:input port="source" primary="true"/>
  <p:input port="schema"/>
  <p:input port="abstract-expansion-xsl">
    <p:document href="../oxy/iso-schematron-abstract.xsl"/>
  </p:input>
  <p:input port="sch2xsl">
    <p:document href="../dist/iso_svrl_for_xslt2.xsl"/>
  </p:input>
  <p:output port="result" primary="true">
    <p:pipe port="source" step="validate-with-schematron"/>
  </p:output>
  <p:output port="report">
    <p:pipe port="result" step="apply-xsl"></p:pipe>
  </p:output>

  <p:variable name="parameters-with-phase" as="map(xs:QName, item()*)" 
    select="map:merge($parameters, map{'phase':$phase})"></p:variable>
  
  <p:xslt>
    <p:with-option name="parameters" select="$parameters"/>
    <p:with-input port="source">
      <p:pipe port="schema" step="validate-with-schematron"/>
    </p:with-input>
    <p:with-input port="stylesheet">
     <p:inline>
       <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
         xmlns:iso="http://purl.oclc.org/dsdl/schematron" version="2.0">
         <xsl:template match="iso:include">
           <xsl:apply-templates select="document(@href)"/>
         </xsl:template>
         
         <xsl:template match="@*| node()">
           <xsl:copy>
             <xsl:apply-templates select="@*, node()"/>
           </xsl:copy>
         </xsl:template>
       </xsl:stylesheet>
     </p:inline>
    </p:with-input>
  </p:xslt>
  
  <p:xslt>
    <p:with-option name="parameters" select="$parameters"/>
    <p:with-input port="stylesheet">
      <p:pipe port="abstract-expansion-xsl" step="validate-with-schematron"/>
    </p:with-input>
  </p:xslt>
  
  <p:xslt name="create-xsl">
    <p:with-option name="parameters" select="$parameters-with-phase"/>
    <p:with-input port="stylesheet">
      <p:pipe port="sch2xsl" step="validate-with-schematron"></p:pipe>
    </p:with-input>
  </p:xslt>
  
  <p:sink/>
  
  <p:xslt>
    <p:with-option name="parameters" select="$parameters-with-phase"/>
    <p:with-input port="source">
      <p:pipe port="source" step="validate-with-schematron"/>
    </p:with-input>
    <p:with-input port="stylesheet">
      <p:pipe port="result" step="create-xsl"/>
    </p:with-input>
  </p:xslt>
  
  <p:add-attribute attribute-name="tr:family" match="/*">
    <p:with-option name="attribute-value" select="$family"/>
  </p:add-attribute>

  <p:add-attribute attribute-name="tr:step-name" name="apply-xsl" match="/*">
    <p:with-option name="attribute-value" select="$step-name"/>
  </p:add-attribute>
  
  <p:sink/>
  
</p:declare-step>