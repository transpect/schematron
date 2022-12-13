<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns="http://www.w3.org/1999/xhtml"
  version="3.0"
  exclude-result-prefixes="svrl s xs html"
  >

  <xsl:param name="collection-uri" as="xs:string?" select="()"/>

  <xsl:variable name="svrl-input" as="document-node(element())+"><!-- svrl:schematron-output or c:errors -->
    <xsl:try>
      <xsl:sequence select="collection($collection-uri)">
        <!-- For invocation from XProc, can be the default collection.
             For direct invocation with Saxon, $collection-uri must be a URI that points
             to something like this:
             <collection>
               <doc href="file:///path/to/1st.svrl"/>
               <doc href="file:///path/to/2nd.svrl"/>
               <doc href="file:///path/to/3rd.svrl"/>
               …
             </collection>
        -->
      </xsl:sequence>
      <xsl:catch>
        <xsl:sequence select="/"/>
      </xsl:catch>
    </xsl:try>
  </xsl:variable>

  <xsl:template match="/" mode="#default">
    <xsl:variable name="doc-uri" select="distinct-values($svrl-input//svrl:active-pattern/@document)" as="xs:string+"/>

    <xsl:variable name="content" as="element(html:tr)*">
      <xsl:variable name="msgs" as="element(*)*"
        select="$svrl-input//svrl:failed-assert | $svrl-input//svrl:successful-report | $svrl-input/c:errors"/>
      <xsl:message select="'DDDDDDDDDDDD ', $svrl-input[1]/base-uri(/*), base-uri(root(.))"/>
      <xsl:if test="$msgs">
        <xsl:for-each-group select="$msgs" 
          group-by="replace(
                      (.//svrl:text/sch:span[@class='srcfile'], replace(base-uri(root(.)/*), '\.val$', ''))[1],
                      '^.+/unzipped/',
                      ''
                    )">
          <xsl:sort select="current-grouping-key()"/>
          <tr xmlns="http://www.w3.org/1999/xhtml" id="file{format-number(position(), '0000')}" class="sep">
            <th colspan="4">
              <xsl:value-of select="current-grouping-key()"/>
            </th>
          </tr>
          <xsl:for-each-group select="current-group()" 
            group-by="(preceding-sibling::svrl:active-pattern[1]/@id,
                        'parse'[current()/self::c:errors[@type='parse']],
                        'XSD'[current()/self::c:errors])[1]">
            <xsl:variable name="active-pattern" select="//svrl:active-pattern[@id = current-grouping-key()]" 
              as="node()?"/>
            <xsl:for-each select="current-group()">
              <tr xmlns="http://www.w3.org/1999/xhtml" id="{generate-id()}">
                <xsl:if test="position() = 1">
                  <xsl:attribute name="class" select="'sep'" />
                </xsl:if>
                <xsl:choose>
                  <xsl:when test="exists($active-pattern)">
                    <td xmlns="http://www.w3.org/1999/xhtml" class="impact {(@role, 'error')[1]}">
                     
                        <xsl:value-of select="(@role, 'error')[1]"/>
                      
                    </td>
                    <td xmlns="http://www.w3.org/1999/xhtml" class="path">
                      
                      <p>
                        <xsl:value-of select="if (not(matches($active-pattern/@document, '\.xpl$'))) then @location else replace(@location, '^.+xproc-step[^/]+(.+)$', '$1')"/>
                      </p>                      
                    </td>
                    <td xmlns="http://www.w3.org/1999/xhtml" class="message">
                      
                        <xsl:apply-templates select="svrl:text/node()[not(self::sch:span[@class eq 'pos'])]" mode="#current"/>
                      
                    </td>
                    <td xmlns="http://www.w3.org/1999/xhtml" class="pattern-id">
                     
                      <xsl:value-of select="replace(@id, '_', '&#x200b;_')"/>
                      
                    </td>
                  </xsl:when>
                  <xsl:otherwise>
                    <td xmlns="http://www.w3.org/1999/xhtml" class="impact error">
                      error
                    </td>
                    <td xmlns="http://www.w3.org/1999/xhtml">
                      <xsl:value-of select="current-grouping-key()"/>
                    </td>
                    <td xmlns="http://www.w3.org/1999/xhtml">
                      <xsl:apply-templates select="self::c:errors"/>
                    </td>
                    <td> </td>
                  </xsl:otherwise>
                </xsl:choose>
              </tr>
            </xsl:for-each>
          </xsl:for-each-group>  
        </xsl:for-each-group>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="ok" as="element(html:tr)+">
      <tr xmlns="http://www.w3.org/1999/xhtml">
        <td class="Status" colspan="4"><p class="ok">Ok</p></td>
      </tr>
    </xsl:variable>

    <xsl:call-template name="output-table">
      <xsl:with-param name="validated-doc-uri" select="$doc-uri" />
      <xsl:with-param name="content" select="if ($content) then $content else $ok" />
    </xsl:call-template>
  </xsl:template>

  <xsl:function name="html:impact-sortkey" as="xs:integer">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="class" select="if($elt/@class) then replace($elt/@class, '\s*impact\s*', '') else ''"/>
    <xsl:choose>
      <xsl:when test="$class = 'fatal'">
        <xsl:sequence select="4"/>
      </xsl:when>
      <xsl:when test="$class = 'error'">
        <xsl:sequence select="3"/>
      </xsl:when>
      <xsl:when test="$class = 'warning'">
        <xsl:sequence select="2"/>
      </xsl:when>
      <xsl:when test="$class = 'info'">
        <xsl:sequence select="1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:template name="statistics">
    <xsl:param name="content" as="element(html:tr)*"/>
    <xsl:param name="td-class" as="xs:string"/>
    <xsl:for-each-group select="$content" group-by="html:td[@class eq $td-class]">
      <xsl:sort select="count(current-group())" order="descending"/>
      <tr xmlns="http://www.w3.org/1999/xhtml">
        <td xmlns="http://www.w3.org/1999/xhtml">
          <xsl:value-of select="current-grouping-key()"/>
        </td>
        <td xmlns="http://www.w3.org/1999/xhtml">
          <a xmlns="http://www.w3.org/1999/xhtml" href="{concat('by-', $td-class)}.html#{current-group()[1]/@id}">
            <xsl:value-of select="count(current-group())"/>
          </a>
        </td>
      </tr>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="output-table">
    <xsl:param name="validated-doc-uri" as="xs:string"/>
    <xsl:param name="pre" as="element(*)*"/>
    <xsl:param name="content" as="element(html:tr)*"/>
    <xsl:if test="$content">
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head xmlns="http://www.w3.org/1999/xhtml">
          <meta charset="UTF-8"/>
          <title xmlns="http://www.w3.org/1999/xhtml">DAV Batch XML Validation</title>
          <style type="text/css">
            body {font-family: Calibri, Helvetica, sans-serif; background-color: #eee}
            @media(min-width: 1200px) {#tr-minitoc {position:fixed; display:block !important; max-width:18%; width:18%; overflow-y:auto; height:100%}}
            #tr-minitoc {display:none}
            ul.nav {padding-left: 10px;}
            ul.nav li {border-left: 2px solid #891e35}
            ul {list-style: none; padding-left:2px;}
            li {padding: 2px 0 2px .5rem;}
            li a {color: #777; text-decoration:none}
            li a:hover {color: #891e35}
            div.header {background-color: #891e35; height: 65px; margin-bottom: 10px;}
            ul.header-list {color: #fff;}
            ul.header-list.right {float: right; padding-right: 2%}
            li.name {font-size: 150%; padding-right: 20px}
            li.date {padding-top: 8px}
            ul.header-list li {float: left;}
            @media(min-width: 1200px) {div.content {width:75% !important; margin-left: 20% !important;}}
            div.content {width:95%; float:left; padding: 10px; background-color: #fff; margin-left: 10px; position: relative}
            table {border-collapse: collapse; border: 1px solid #eee; table-layout: fixed; width: 100%; word-break: break-word}            
            tr.head th {background-color: #ccc;}
            th {background-color: #eee;}
            td, th { vertical-align: top; padding: 0.5em; text-align:left; border-color:#000 }
            td.path p { margin-top: 0; margin-bottom: 0.5em; }
            .ok { color: #6d6; font-weight: bold; }
            .info { color: #ddd; font-weight: bold; }
            .warning { color: #FFB935; font-weight: bold; }
            .error { color: #ff1400; font-weight: bold; }
            .fatal { color: #f39; font-weight: bold; }
          </style>          
        </head>
        <body xmlns="http://www.w3.org/1999/xhtml">
          <div class="header">
            <ul class="header-list">
              <li><img class="logo" src="http://this.transpect.io/a9s/common/template/icons/dav.svg"/></li>
            </ul>
            <ul class="header-list right">
              <li class="name">Batch XML Validation</li>
              <li class="date">
                <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01], [H01]:[m01]')"/>
              </li>
            </ul>
          </div>
          <xsl:sequence select="$pre"/>
          <nav id="tr-minitoc" class="navbar-minitoc">
            <ul class="BC_minitoc nav">
              <li class="hidden active">
                <a class="page-scroll" href="#page-top"/>
              </li>
              <xsl:for-each select="$content[html:th]">
                <li class="BC_minitoc-item">
                  <a class="page-scroll" href="#file{format-number(position(), '0000')}">
                    <xsl:value-of select="tokenize(current()/html:th, '/')[last()]"/>
                  </a>
                </li>
              </xsl:for-each>
            </ul>
          </nav>
          <div class="content">
            <table xmlns="http://www.w3.org/1999/xhtml" border="1" valign="top">
              <tr xmlns="http://www.w3.org/1999/xhtml" class="head">
                <th xmlns="http://www.w3.org/1999/xhtml" style="width:10%">severity</th>
                <th xmlns="http://www.w3.org/1999/xhtml" style="width:40%">path / test</th>
                <th xmlns="http://www.w3.org/1999/xhtml" style="width:40%">message</th>
                <th xmlns="http://www.w3.org/1999/xhtml" style="width:10%">pattern-id</th>
              </tr>
              <xsl:sequence select="$content"/>
            </table>
          </div>
        </body> 
        <script src="http://this.transpect.io/a9s/common/template/js/jquery-2.1.4.min.js"></script>
        <script src="http://this.transpect.io/a9s/common/template/js/jquery.easing.1.3.js"/>
        <script src="http://this.transpect.io/a9s/common/template/js/scrolling-nav.js"/>
      </html>
    </xsl:if>
  </xsl:template>

  <xsl:variable name="block-names" as="xs:string+" select="('dl', 'div', 'ol', 'ul', 'c:errors')"/>

  <xsl:template match="svrl:schematron-output/svrl:text" mode="#default">
    <xsl:for-each-group select="node()" group-adjacent="name() = $block-names">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:apply-templates select="current-group()" mode="#current" />
        </xsl:when>
        <xsl:otherwise>
          <p>
            <xsl:apply-templates select="current-group()" mode="#current" />
          </p>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="sch:span[@class = 'srcfile']" mode="#default"/>

  <xsl:template match="c:errors" mode="#default">
    <dl class="errors">
      <xsl:apply-templates mode="#current"/>
    </dl>
  </xsl:template>
  
  <xsl:template match="c:ok" mode="#default"/>

  <xsl:template match="c:error" mode="#default">
    <dt>
      <xsl:value-of select="@code"/>
    </dt>
    <dd>
      <xsl:apply-templates select="@line, node()" mode="#current"/>
    </dd>
  </xsl:template>
  
  <xsl:template match="c:error/text()" mode="#default">
    <xsl:value-of select="replace(., '^.+file:.+?;\s*', '')"/>
  </xsl:template>

  <xsl:template match="s:emph" mode="#default">
    <em xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates mode="#current" />
    </em>
  </xsl:template>

  <xsl:template match="* | @*" mode="#default">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>