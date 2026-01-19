<%@ Page Language="VB" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Hello World - ASPX VB</title>
    
    <!-- External CDN JavaScript References with both HTTP and HTTPS -->
    <script src="https://code.jquery.com/jquery-2.2.4.min.js"></script>
    <script src="https://maps.google.com/maps/api/js?v=3"></script>
    <script src="http://maps.google.com/maps/api/js?libraries=places"></script>
    <script src="https://cdn.jsdelivr.net/npm/vue@2.6.14/dist/vue.js"></script>
    <script src="https://unpkg.com/react@17/umd/react.production.min.js"></script>
</head>
<body>
    <form id="form1" runat="server">
        <h1>Hello World from VB.NET ASPX!</h1>
        <p>This page includes multiple external JavaScript CDN sources.</p>
        
        <div id="app">
            <p>{{ message }}</p>
        </div>
    </form>
    
    <script>
        // jQuery usage
        $(function() {
            console.log('jQuery from CDN ready');
        });
        
        // Vue.js usage
        var app = new Vue({
            el: '#app',
            data: {
                message: 'Vue.js loaded from CDN!'
            }
        });
    </script>
</body>
</html>
