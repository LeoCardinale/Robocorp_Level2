*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Variables ***
${url_website}          https://robotsparebinindustries.com/#/robot-order
${url_orders_csv}       https://robotsparebinindustries.com/orders.csv
${path_downloads}       ${OUTPUT_DIR}${/}Downloads
${button_locator}       css:button.btn-dark
${orders_filename}      orders.csv
${path_output_pdf}      ${OUTPUT_DIR}${/}Orders
${path_screenshots}     ${OUTPUT_DIR}${/}Screenshots


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the Orders file
    Load table and loop over it
    Zip orders
    [Teardown]    Log out and close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    ${url_website}    maximized=True
    Close pop-up

Close pop-up
    Click Element If Visible    ${button_locator}

Download the Orders file
    Download    ${url_orders_csv}    target_file=${path_downloads}${/}${orders_filename}    overwrite=True

Load table and loop over it
    ${dt_orders}=    Get Orders
    FOR    ${row}    IN    @{dt_orders}
        Fill and submit the robot order    ${row}
        ${path_pdf_order}=    Store the order as a PDF    ${row}[Order number]
        ${order_screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the PDF    ${order_screenshot}    ${path_pdf_order}
        Click Button    id:order-another
        Close pop-up
    END

Get Orders
    ${table}=    Read table from CSV    ${path_downloads}${/}${orders_filename}
    RETURN    ${table}

Fill and submit the robot order
    [Arguments]    ${my_row}
    Select From List By Value    head    ${my_row}[Head]
    Select Radio Button    body    ${my_row}[Body]
    Input Text    xpath://input[contains(@placeholder, 'for the legs')]    ${my_row}[Legs]
    Input Text    address    ${my_row}[Address]
    Click Button    id:preview
    Wait Until Keyword Succeeds    1 min    2 sec    Submit the order
    Log    Order issued!

Submit the order
    Click Button    id:order
    Assert order is completed

Assert order is completed
    Element Should Be Visible    id:order-completion

Store the order as a PDF
    [Arguments]    ${this_order}
    ${path_this_pdf}=    Set Variable    ${path_output_pdf}${/}order_${this_order}.pdf
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${path_this_pdf}
    RETURN    ${path_this_pdf}

Take a screenshot of the robot
    [Arguments]    ${this_order}
    ${path_this_preview}=    Set Variable    ${path_screenshots}${/}preview_${this_order}.png
    Screenshot    id:robot-preview-image    ${path_this_preview}
    RETURN    ${path_this_preview}

Embed the robot screenshot to the PDF
    [Arguments]    ${screenshot}    ${pdf}
    #Mute Run On Failure    Run Keyword
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Zip orders
    ${path_zip_file}=    Set Variable    ${OUTPUT_DIR}${/}Orders_PDF.zip
    Archive Folder With Zip
    ...    ${path_output_pdf}
    ...    ${path_zip_file}
    TRY
        File Should Exist    ${path_zip_file}
    EXCEPT
        Log    Failed to zip the orders
    ELSE
        Log    Orders zipped successfully!
    END

Log out and close the browser
    Close Browser
