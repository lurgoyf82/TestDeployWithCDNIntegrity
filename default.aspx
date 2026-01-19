<%@ Page Language="C#" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="UTF-8" />
    <title>Hello World - ASPX</title>
    
    <!-- External CDN JavaScript References -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="http://maps.google.com/maps/api/js?sensor=false"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.21/lodash.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <h1>Hello World from ASPX!</h1>
            <p>This is an ASP.NET Web Forms page with external CDN references.</p>
            
            <asp:Label ID="lblMessage" runat="server" Text="Welcome to ASP.NET"></asp:Label>
            
            <div id="map-container" style="height: 400px; width: 100%;"></div>
        </div>
    </form>
    
    <script type="text/javascript">
        // Using jQuery from CDN
        $(document).ready(function() {
            console.log('jQuery loaded from CDN in ASPX page');
        });
        
        // Using Lodash from CDN
        if (typeof _ !== 'undefined') {
            console.log('Lodash loaded from CDN');
        }
    </script>
</body>
</html>
