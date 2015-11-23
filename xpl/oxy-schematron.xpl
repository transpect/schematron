<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:tr="http://transpect.io"
  type="tr:oxy-validate-with-schematron"
  name="validate-with-schematron"
  version="1.0">
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
  <p:input port="source" primary="true"/>
  <p:input port="schema"/>
  <p:input port="parameters" kind="parameter" primary="true"/>
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

  <p:xslt>
    <p:input port="source">
      <p:pipe port="schema" step="validate-with-schematron"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="parameters" step="validate-with-schematron"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="abstract-expansion-xsl" step="validate-with-schematron"/>
    </p:input>
  </p:xslt>
  
  <p:xslt name="create-xsl">
    <p:input port="parameters">
      <p:pipe port="parameters" step="validate-with-schematron"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="sch2xsl" step="validate-with-schematron"></p:pipe>
    </p:input>
    <p:with-param name="phase" select="$phase"/>
  </p:xslt>
  
  <p:sink/>
  
  <p:xslt>
    <p:input port="source">
      <p:pipe port="source" step="validate-with-schematron"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="parameters" step="validate-with-schematron"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="result" step="create-xsl"/>
    </p:input>
  </p:xslt>
  
  <p:add-attribute attribute-name="tr:family" match="/*">
    <p:with-option name="attribute-value" select="$family"/>
  </p:add-attribute>
  
  <p:add-attribute attribute-name="tr:step-name" name="apply-xsl" match="/*">
    <p:with-option name="attribute-value" select="$step-name"/>
  </p:add-attribute>
  
  <p:sink/>
  
</p:declare-step>