$(document).ready(function() {
    // Function to show Bootstrap loading modal with a message
    function showLoadingModal(message) {
        if (!$("#loadingModal").length) {
            const modalHtml = `
                <div class="modal fade" id="loadingModal" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog modal-dialog-centered">
                        <div class="modal-content">
                            <div class="modal-body text-center">
                                <div class="spinner-border text-primary" role="status">
                                    <span class="visually-hidden">Loading...</span>
                                </div>
                                <p id="loadingMessage" class="mt-3"></p>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            $("body").append(modalHtml);
        }
        $("#loadingMessage").text(message);
        $("#loadingModal").modal({ backdrop: "static", keyboard: false });
    }

    // Function to hide loading modal
    function hideLoadingModal() {
        $("#loadingModal").modal("hide");
    }

    // Function to submit time entry using Power Pages Web API
    function submitTimeEntry(formData) {
        showLoadingModal("Submitting time entry...");

        return $.ajax({
            url: "/_api/timeentries", // Power Pages Web API endpoint
            method: "POST",
            headers: {
                "__RequestVerificationToken": $("input[name='__RequestVerificationToken']").val(), // CSRF token
                "Accept": "application/json",
                "Content-Type": "application/json"
            },
            data: JSON.stringify(formData),
        });
    }

    // Function to check for meal ticket creation
    function checkMealTicket(timeEntryId, maxAttempts = 30, interval = 2000) {
        let attempt = 0;

        return new Promise((resolve, reject) => {
            showLoadingModal("Creating meal ticket record...");
            const checkInterval = setInterval(function() {
                attempt++;
                $.ajax({
                    url: `/_api/mealtickets?$filter=timeentryid eq '${timeEntryId}'`, // Adjust field name as per schema
                    method: "GET",
                    headers: {
                        "__RequestVerificationToken": $("input[name='__RequestVerificationToken']").val(),
                        "Accept": "application/json"
                    },
                    success: function(data) {
                        if (data.value && data.value.length > 0) {
                            clearInterval(checkInterval);
                            resolve(data.value[0].mealticketid);
                        } else if (attempt >= maxAttempts) {
                            clearInterval(checkInterval);
                            reject("Timeout waiting for meal ticket creation.");
                        }
                    },
                    error: function(xhr) {
                        clearInterval(checkInterval);
                        reject("Error checking meal ticket: " + xhr.responseText);
                    }
                });
            }, interval);
        });
    }

    // Function to check for Word document in Notes
    function checkWordDocument(timeEntryId, maxAttempts = 30, interval = 2000) {
        let attempt = 0;

        return new Promise((resolve, reject) => {
            showLoadingModal("Generating Word document in Notes...");
            const checkInterval = setInterval(function() {
                attempt++;
                $.ajax({
                    url: `/_api/annotations?$filter=objectid_timeentry eq '${timeEntryId}' and filename like '%.docx'`, // Adjust lookup field
                    method: "GET",
                    headers: {
                        "__RequestVerificationToken": $("input[name='__RequestVerificationToken']").val(),
                        "Accept": "application/json"
                    },
                    success: function(data) {
                        if (data.value && data.value.length > 0) {
                            clearInterval(checkInterval);
                            resolve(data.value[0].annotationid);
                        } else if (attempt >= maxAttempts) {
                            clearInterval(checkInterval);
                            reject("Timeout waiting for Word document creation.");
                        }
                    },
                    error: function(xhr) {
                        clearInterval(checkInterval);
                        reject("Error checking Word document: " + xhr.responseText);
                    }
                });
            }, interval);
        });
    }

    // Function to poll for PDF in Notes
    function checkPdfDocument(timeEntryId, maxAttempts = 30, interval = 2000) {
        let attempt = 0;

        return new Promise((resolve, reject) => {
            showLoadingModal("Converting Word document to PDF...");
            const checkInterval = setInterval(function() {
                attempt++;
                $.ajax({
                    url: `/_api/annotations?$filter=objectid_timeentry eq '${timeEntryId}' and filename like '%.pdf'`, // Adjust lookup field
                    method: "GET",
                    headers: {
                        "__RequestVerificationToken": $("input[name='__RequestVerificationToken']").val(),
                        "Accept": "application/json"
                    },
                    success: function(data) {
                        if (data.value && data.value.length > 0) {
                            clearInterval(checkInterval);
                            resolve(data.value[0].annotationid);
                        } else if (attempt >= maxAttempts) {
                            clearInterval(checkInterval);
                            reject("Timeout waiting for PDF creation.");
                        }
                    },
                    error: function(xhr) {
                        clearInterval(checkInterval);
                        reject("Error checking PDF: " + xhr.responseText);
                    }
                });
            }, interval);
        });
    }

    // Handle form submission
    $("#timeEntryForm").on("submit", function(e) {
        e.preventDefault();

        // Collect form data (adjust fields based on your schema)
        const formData = {
            "timeentryname": $("#timeEntryName").val(), // Example field
            "duration": parseInt($("#duration").val()), // Example field
            // Add other required fields for timeentry
        };

        // Chain the process steps
        submitTimeEntry(formData)
            .then(function(response) {
                const timeEntryId = response.timeentryid; // Power Pages Web API returns ID directly in response
                return checkMealTicket(timeEntryId);
            })
            .then(function(mealTicketId) {
                return checkWordDocument(formData.timeentryid || mealTicketId); // Use timeEntryId or adjust based on schema
            })
            .then(function(wordDocId) {
                return checkPdfDocument(formData.timeentryid || wordDocId); // Use timeEntryId or adjust based on schema
            })
            .then(function(pdfId) {
                hideLoadingModal();
                alert("Process completed successfully! PDF is ready.");
            })
            .catch(function(error) {
                hideLoadingModal();
                alert("Error: " + error);
            });
    });
});