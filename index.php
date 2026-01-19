<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World - PHP</title>
    
    <!-- External CDN JavaScript References -->
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="http://maps.google.com/maps/api/js?key=API_KEY"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js"></script>
    
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>
<body>
    <div class="container mt-5">
        <h1>Hello World from PHP!</h1>
        <p>Current server time: <?php echo date('Y-m-d H:i:s'); ?></p>
        <p>This PHP page includes external CDN JavaScript sources.</p>
        
        <div id="message"></div>
    </div>
    
    <script>
        $(document).ready(function() {
            $('#message').html('jQuery and other CDN libraries loaded successfully!');
            console.log('Moment.js version:', moment.version);
        });
    </script>
</body>
</html>
