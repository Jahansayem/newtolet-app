$('#search_division').on('change', function (e) {
    var division_id = e.target.value;
    var country = $("html").data('country');
    var route_link = window.location.origin + '/' + country + '/ajax-divtodis';
    $.get(route_link + '?division_id=' + division_id, function (data) {
        $('#search_district').empty();
        $('#search_area').empty();
        $('#search_subarea').empty();
        $('#search_subarea_box').hide();
        $('#search_district').append('<option value="">Select district</option>');
        $.each(data, function (value, display) {
            $('#search_district').append('<option value="' + display.id + '">' + display
                .name +
                '</option>');
        });
        $('#search_area').append('<option value="">Select district first</option>');
    });
});

$('#search_district').on('change', function (e) {
    var district_id = e.target.value;
    var country = $("html").data('country');
    var route_link = window.location.origin + '/' + country + '/ajax-distoarea';
    $.get(route_link + '?district_id=' + district_id, function (data) {
        $('#search_area').empty();
        $('#search_area').append('<option value="">Select area</option>');
        $('#search_subarea').empty();
        $('#search_subarea_box').hide();
        $.each(data, function (value, display) {
            $('#search_area').append('<option value="' + display.id + '">' + display.name +
                '</option>');
        });
    });
});

$('#search_area').on('change', function (e) {
    var area_id = e.target.value;
    var country = $("html").data('country');
    var route_link = window.location.origin + '/' + country + '/ajax-areatosubarea';
    $.get(route_link + '?area_id=' + area_id, function (data) {

        if (data.length > 0) {
            $('#search_subarea').empty();
            $('#search_subarea_box').show();
            $('#search_subarea').append('<option value="">Select sub area</option>');
        } else {
            $('#search_subarea').empty();
            $('#search_subarea_box').hide();
        }
        $.each(data, function (value, display) {
            $('#search_subarea').append('<option value="' + display.id + '">' + display.name +
                '</option>');
        });
    });
});


$('#division').on('change', function (e) {
    var division_id = e.target.value;
    var country = $("html").data('country');
    var route_link = window.location.origin + '/' + country + '/ajax-divtodis';
    $.get(route_link + '?division_id=' + division_id, function (data) {
        $('#district').empty();
        $('#area').empty();
        $('#district').append('<option value="">Select district first</option>');
        $('#subarea').empty();
        $('#subarea_box').hide();
        $.each(data, function (value, display) {
            $('#district').append('<option value="' + display.id + '">' + display.name +
                '</option>');
        });
        $('#area').append('<option value="">Select district first</option>');
    });
});

$('#district').on('change', function (e) {
    var district_id = e.target.value;
    var country = $("html").data('country');
    var route_link = window.location.origin + '/' + country + '/ajax-distoarea';
    $.get(route_link + '?district_id=' + district_id, function (data) {
        $('#area').empty();
        $('#area').append('<option value="">Select area</option>');
        $('#subarea').empty();
        $('#subarea_box').hide();
        $.each(data, function (value, display) {
            $('#area').append('<option value="' + display.id + '">' + display.name +
                '</option>');
        });
    });
});


$('#area').on('change', function (e) {
    var area_id = e.target.value;
    var country = $("html").data('country');
    var route_link = window.location.origin + '/' + country + '/ajax-areatosubarea';
    $.get(route_link + '?area_id=' + area_id, function (data) {
        console.log(data.length);
        if (data.length > 0) {
            $('#subarea').empty();
            $('#subarea_box').show();
            $('#subarea').append('<option value="">Select sub area</option>');
        }
        else {
            $('#subarea').empty();
            $('#subarea_box').hide();
        }
        $.each(data, function (value, display) {
            $('#subarea').append('<option value="' + display.id + '">' + display.name +
                '</option>');
        });
    });
});