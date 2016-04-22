<%@ Page Language="C#" AutoEventWireup="true" %>
<%
    var LastModified = DateTime.UtcNow.ToString("yyyy-MM-dd");
    Response.ContentType = "text/xml";
    Response.Charset = "UTF-8";
%><?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://support.west-wind.com</loc>    
    <lastmod><%= LastModified %></lastmod>
    <changefreq>daily</changefreq>     
    <priority>1</priority>
  </url>
  <url>
    <loc>https://support.west-wind.com/threadlist.wwt</loc>
    <lastmod><%= LastModified %></lastmod>
    <changefreq>daily</changefreq>
    <priority>1</priority>
  </url>
</urlset>
