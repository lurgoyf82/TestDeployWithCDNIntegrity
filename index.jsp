<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Hello World - JSP</title>
    
    <!-- External CDN JavaScript References with HTTP and HTTPS variants -->
    <script src="https://code.jquery.com/jquery-3.6.0.js"></script>
    <script src="https://maps.googleapis.com/maps/api/js?v=3.exp"></script>
    <script src="http://maps.google.com/maps/api/js?sensor=true"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.5.1/dist/chart.min.js"></script>
    <script src="https://unpkg.com/dayjs@1.10.7/dayjs.min.js"></script>
</head>
<body>
    <h1>Hello World from JSP!</h1>
    <p>Server info: <%= application.getServerInfo() %></p>
    <p>Session ID: <%= session.getId() %></p>
    
    <canvas id="myChart" width="400" height="200"></canvas>
    
    <script>
        // jQuery
        $(function() {
            console.log('jQuery loaded from CDN in JSP page');
        });
        
        // Day.js
        console.log('Current date:', dayjs().format('YYYY-MM-DD HH:mm:ss'));
    </script>
</body>
</html>
