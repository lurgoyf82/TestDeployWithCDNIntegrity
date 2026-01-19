# CDN Integrity Test Pages

This repository contains example "Hello World" pages in various web languages, each containing external JavaScript CDN references for testing CDN integrity checkers.

## Files Created

### HTML Pages
1. **index.html** - Basic HTML page
   - https://code.jquery.com/jquery-3.6.0.min.js
   - https://maps.googleapis.com/maps/api/js
   - https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js

2. **advanced.html** - Advanced HTML with comprehensive CDN references
   - https://code.jquery.com/jquery-3.6.0.min.js
   - https://code.jquery.com/ui/1.12.1/jquery-ui.min.js
   - http://maps.google.com/maps/api/js
   - https://maps.google.com/maps/api/js
   - https://maps.googleapis.com/maps/api/js
   - https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js
   - https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.13.1/underscore-min.js
   - https://unpkg.com/axios@0.21.1/dist/axios.min.js
   - https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js

### ASPX Pages (ASP.NET)
3. **default.aspx** - ASP.NET C# Web Forms page
   - https://code.jquery.com/jquery-3.6.0.min.js
   - http://maps.google.com/maps/api/js (HTTP variant)
   - https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.21/lodash.min.js
   - https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js

4. **hello.aspx** - ASP.NET VB.NET Web Forms page
   - https://code.jquery.com/jquery-2.2.4.min.js
   - https://maps.google.com/maps/api/js (HTTPS variant)
   - http://maps.google.com/maps/api/js (HTTP variant)
   - https://cdn.jsdelivr.net/npm/vue@2.6.14/dist/vue.js
   - https://unpkg.com/react@17/umd/react.production.min.js

### PHP Pages
5. **index.php** - PHP page
   - https://code.jquery.com/jquery-3.5.1.min.js
   - http://maps.google.com/maps/api/js (HTTP variant)
   - https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/js/bootstrap.bundle.min.js
   - https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js

### JSP Pages (Java Server Pages)
6. **index.jsp** - JSP page
   - https://code.jquery.com/jquery-3.6.0.js
   - https://maps.googleapis.com/maps/api/js
   - http://maps.google.com/maps/api/js (HTTP variant)
   - https://cdn.jsdelivr.net/npm/chart.js@3.5.1/dist/chart.min.js
   - https://unpkg.com/dayjs@1.10.7/dayjs.min.js

## Key Features for CDN Integrity Testing

### CDN Sources Included:
- **jQuery**: https://code.jquery.com (multiple versions)
- **Google Maps**: Both HTTP and HTTPS variants
  - http://maps.google.com/maps/api/js
  - https://maps.google.com/maps/api/js
  - https://maps.googleapis.com/maps/api/js
- **Bootstrap**: https://cdn.jsdelivr.net/npm/bootstrap
- **Vue.js**: https://cdn.jsdelivr.net/npm/vue
- **React**: https://unpkg.com/react
- **Lodash**: https://cdn.jsdelivr.net/npm/lodash
- **Axios**: https://cdn.jsdelivr.net/npm/axios
- **Moment.js**: https://cdnjs.cloudflare.com/ajax/libs/moment.js
- **Chart.js**: https://cdn.jsdelivr.net/npm/chart.js
- **Underscore.js**: https://cdnjs.cloudflare.com/ajax/libs/underscore.js

### Protocol Variants:
- Pages include both HTTP (`http://`) and HTTPS (`https://`) CDN references
- Specifically includes the requested patterns:
  - `http://maps.google.com`
  - `https://code.jquery.com`
  - `https://maps.google.com`

### Language Extensions:
- ✅ `.html` - Standard HTML pages
- ✅ `.aspx` - ASP.NET Web Forms (C# and VB.NET)
- ✅ `.php` - PHP pages
- ✅ `.jsp` - Java Server Pages

## Purpose

These pages are designed to test a CDN integrity checker that will:
- Scan web pages for external JavaScript references
- Validate CDN sources
- Check for security issues with external dependencies
- Test both HTTP and HTTPS protocol handling
- Work across multiple web technology stacks
